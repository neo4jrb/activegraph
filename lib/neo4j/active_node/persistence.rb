module Neo4j::ActiveNode
  module Persistence
    class RecordInvalidError < RuntimeError
      attr_reader :record

      def initialize(record)
        @record = record
        super(@record.errors.full_messages.join(', '))
      end
    end

    extend ActiveSupport::Concern
    extend Forwardable
    include Neo4j::Shared::Persistence

    # Saves the model.
    #
    # If the model is new a record gets created in the database, otherwise the existing record gets updated.
    # If perform_validation is true validations run.
    # If any of them fail the action is cancelled and save returns false.
    # If the flag is false validations are bypassed altogether.
    # See ActiveRecord::Validations for more information.
    # There's a series of callbacks associated with save.
    # If any of the before_* callbacks return false the action is cancelled and save returns false.
    def save(*)
      cascade_save do
        association_proxy_cache.clear
        create_or_update
      end
    end

    # Persist the object to the database.  Validations and Callbacks are included
    # by default but validation can be disabled by passing :validate => false
    # to #save!  Creates a new transaction.
    #
    # @raise a RecordInvalidError if there is a problem during save.
    # @param (see Neo4j::Rails::Validations#save)
    # @return nil
    # @see #save
    # @see Neo4j::Rails::Validations Neo4j::Rails::Validations - for the :validate parameter
    # @see Neo4j::Rails::Callbacks Neo4j::Rails::Callbacks - for callbacks
    def save!(*args)
      save(*args) or fail(RecordInvalidError, self) # rubocop:disable Style/AndOr
    end

    # Creates a model with values matching those of the instance attributes and returns its id.
    # @private
    # @return true
    def create_model
      node = _create_node(props_for_create)
      init_on_load(node, node.props)
      send_props(@relationship_props) if @relationship_props
      @relationship_props = @deferred_nodes = nil
      true
    end

    # TODO: This does not seem like it should be the responsibility of the node.
    # Creates an unwrapped node in the database.
    # @param [Hash] node_props The type-converted properties to be added to the new node.
    # @param [Array] labels The labels to use for creating the new node.
    # @return [Neo4j::Node] A CypherNode or EmbeddedNode
    def _create_node(node_props, labels = labels_for_create)
      self.class.neo4j_session.create_node(node_props, labels)
    end

    # As the name suggests, this inserts the primary key (id property) into the properties hash.
    # The method called here, `default_property_values`, is a holdover from an earlier version of the gem. It does NOT
    # contain the default values of properties, it contains the Default Property, which we now refer to as the ID Property.
    # It will be deprecated and renamed in a coming refactor.
    # @param [Hash] converted_props A hash of properties post-typeconversion, ready for insertion into the DB.
    def inject_primary_key!(converted_props)
      self.class.default_property_values(self).tap do |destination_props|
        destination_props.merge!(converted_props) if converted_props.is_a?(Hash)
      end
    end

    # @return [Array] Labels to be set on the node during a create event
    def labels_for_create
      self.class.mapped_label_names
    end

    private

    # The pending associations are cleared during the save process, so it's necessary to
    # build the processable hash before it begins. If there are nodes and associations that
    # need to be created after the node is saved, a new transaction is started.
    def cascade_save
      deferred_nodes = pending_associations_with_nodes
      Neo4j::Transaction.run(!deferred_nodes.blank?) do
        result = yield
        process_unpersisted_nodes!(deferred_nodes) if deferred_nodes
        result
      end
    end

    module ClassMethods
      # Creates and saves a new node
      # @param [Hash] props the properties the new node should have
      def create(props = {})
        association_props = extract_association_attributes!(props) || {}
        new(props).tap do |obj|
          yield obj if block_given?
          obj.save
          association_props.each do |prop, value|
            obj.send("#{prop}=", value)
          end
        end
      end

      # Same as #create, but raises an error if there is a problem during save.
      def create!(*args)
        props = args[0] || {}
        association_props = extract_association_attributes!(props) || {}

        new(*args).tap do |o|
          yield o if block_given?
          o.save!
          association_props.each do |prop, value|
            o.send("#{prop}=", value)
          end
        end
      end

      def merge(attributes)
        neo4j_session.query.merge(n: {self.mapped_label_names => attributes})
          .on_create_set(n: on_create_props(attributes))
          .on_match_set(n: on_match_props)
          .pluck(:n).first
      end

      def find_or_create(find_attributes, set_attributes = {})
        on_create_attributes = set_attributes.merge(on_create_props(find_attributes))
        on_match_attributes =  set_attributes.merge(on_match_props)
        neo4j_session.query.merge(n: {self.mapped_label_names => find_attributes})
          .on_create_set(n: on_create_attributes).on_match_set(n: on_match_attributes)
          .pluck(:n).first
      end

      # Finds the first node with the given attributes, or calls create if none found
      def find_or_create_by(attributes, &block)
        find_by(attributes) || create(attributes, &block)
      end

      # Same as #find_or_create_by, but calls #create! so it raises an error if there is a problem during save.
      def find_or_create_by!(attributes, &block)
        find_by(attributes) || create!(attributes, &block)
      end

      def load_entity(id)
        Neo4j::Node.load(id)
      end

      private

      def on_create_props(find_attributes)
        find_attributes.merge(self.new(find_attributes).props_for_create)
      end

      def on_match_props
        {}.tap { |props| props[:updated_at] = DateTime.now.to_i if attributes_nil_hash.key?('updated_at'.freeze) }
      end
    end
  end
end
