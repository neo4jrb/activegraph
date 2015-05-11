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
      update_magic_properties
      clear_association_cache
      create_or_update
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
      fail RecordInvalidError, self unless save(*args)
    end

    # Creates a model with values matching those of the instance attributes and returns its id.
    # @private
    # @return true
    def create_model(*)
      create_magic_properties
      set_timestamps
      create_magic_properties
      properties = self.class.declared_property_manager.convert_properties_to(self, :db, props)
      node = _create_node(properties)
      init_on_load(node, node.props)
      send_props(@relationship_props) if @relationship_props
      @relationship_props = nil
      true
    end

    def _create_node(*args)
      session = self.class.neo4j_session
      props = self.class.default_property_values(self)
      props.merge!(args[0]) if args[0].is_a?(Hash)
      set_classname(props)
      labels = self.class.mapped_label_names
      session.create_node(props, labels)
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
        {id_property_name => id_prop_val(find_attributes)}.tap do |props|
          now = DateTime.now.to_i
          set_props_timestamp!('created_at', props, now)
          set_props_timestamp!('updated_at', props, now)
        end
      end

      # The process of creating custom id_property values is different from auto uuids. This adapts to that, calls the appropriate method,
      # and raises an error if it fails.
      def id_prop_val(find_attributes)
        custom_uuid_method = id_property_info[:type][:on]
        id_prop_val = custom_uuid_method ? self.new(find_attributes).send(custom_uuid_method) : default_properties[id_property_name].call
        fail 'Unable to create custom id property' if id_prop_val.nil?
        id_prop_val
      end

      def on_match_props
        set_props_timestamp!('updated_at')
      end

      def set_props_timestamp!(key_name, props = {}, stamp = DateTime.now.to_i)
        props[key_name.to_sym] = stamp if attributes_nil_hash.key?(key_name)
        props
      end
    end
  end
end
