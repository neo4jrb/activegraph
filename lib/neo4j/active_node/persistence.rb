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

    # Increments concurrently a numeric attribute by a centain amount
    # @param [Symbol, String] name of the attribute to increment
    # @param [Integer, Float] amount to increment
    def concurrent_increment!(attribute, by = 1)
      query_node = Neo4j::Session.query.match_nodes(n: neo_id)
      increment_by_query! query_node, attribute, by
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
      @deferred_nodes = nil
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
      Neo4j::Transaction.run(pending_deferred_creations?) do
        result = yield
        process_unpersisted_nodes!
        result
      end
    end

    module ClassMethods
      # Creates and saves a new node
      # @param [Hash] props the properties the new node should have
      def create(props = {})
        new(props).tap do |obj|
          yield obj if block_given?
          obj.save
        end
      end

      # Same as #create, but raises an error if there is a problem during save.
      def create!(props = {})
        new(props).tap do |o|
          yield o if block_given?
          o.save!
        end
      end

      def merge(match_attributes, optional_attrs = {})
        options = [:on_create, :on_match, :set]
        optional_attrs.assert_valid_keys(*options)

        optional_attrs.default = {}
        on_create_attrs, on_match_attrs, set_attrs = optional_attrs.values_at(*options)

        neo4j_session.query.merge(n: {self.mapped_label_names => match_attributes})
          .on_create_set(on_create_clause(on_create_attrs))
          .on_match_set(on_match_clause(on_match_attrs))
          .break.set(n: set_attrs)
          .pluck(:n).first
      end

      def find_or_create(find_attributes, set_attributes = {})
        on_create_attributes = set_attributes.reverse_merge(find_attributes.merge(self.new(find_attributes).props_for_create))

        neo4j_session.query.merge(n: {self.mapped_label_names => find_attributes})
          .on_create_set(n: on_create_attributes)
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

      def on_create_clause(clause)
        if clause.is_a?(Hash)
          {n: clause.merge(self.new(clause).props_for_create)}
        else
          clause
        end
      end

      def on_match_clause(clause)
        if clause.is_a?(Hash)
          {n: clause.merge(attributes_nil_hash.key?('updated_at') ? {updated_at: Time.new.to_i} : {})}
        else
          clause
        end
      end
    end
  end
end
