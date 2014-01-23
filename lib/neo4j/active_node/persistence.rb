module Neo4j::ActiveNode
  module Persistence
    class RecordInvalidError < RuntimeError
      attr_reader :record

      def initialize(record)
        @record = record
        super(@record.errors.full_messages.join(", "))
      end
    end

    extend ActiveSupport::Concern
    include Neo4j::TypeConverters

    # Saves the model.
    #
    # If the model is new a record gets created in the database, otherwise the existing record gets updated.
    # If perform_validation is true validations run.
    # If any of them fail the action is cancelled and save returns false. If the flag is false validations are bypassed altogether. See ActiveRecord::Validations for more information.
    # There’s a series of callbacks associated with save. If any of the before_* callbacks return false the action is cancelled and save returns false.
    def save(*)
      # Update magic properties
      update_magic_properties
      create_or_update
    end

    def update_magic_properties
      self.updated_at = DateTime.now if respond_to?(:updated_at=)
    end

    # Creates a model with values matching those of the instance attributes and returns its id.
    # @private
    # @return true
    def create_model(*)
      self.created_at = DateTime.now if respond_to?(:created_at=)
      properties = convert_properties_to :db, props
      node = _create_node(properties)
      init_on_load(node, node.props)
      # Neo4j::IdentityMap.add(node, self)
      # write_changed_relationships
      true
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
      unless save(*args)
        raise RecordInvalidError.new(self)
      end
    end

    def create_or_update
      # since the same model can be created or updated twice from a relationship we have to have this guard
      @_create_or_updating = true
      result = persisted? ? update_model : create_model
      unless result != false
        Neo4j::Transaction.current.fail if Neo4j::Transaction.current
        false
      else
        true
      end
    rescue => e
      Neo4j::Transaction.current.fail if Neo4j::Transaction.current
      raise e
    ensure
      @_create_or_updating = nil
    end

    def exist?
      _persisted_node && _persisted_node.exist?
    end

    # Returns +true+ if the object was destroyed.
    def destroyed?
      @_deleted || (!new_record? && !exist?)
    end

    # Returns +true+ if the record is persisted, i.e. it’s not a new record and it was not destroyed
    def persisted?
      !new_record? && !destroyed?
    end

    # Returns +true+ if the record hasn't been saved to Neo4j yet.
    def new_record?
      ! _persisted_node
    end

    alias :new? :new_record?

    def destroy
      _persisted_node && _persisted_node.del
      @_deleted = true
    end

    def update_model
      if @changed_attributes && !@changed_attributes.empty?
        changed_props = attributes.select{|k,v| @changed_attributes.include?(k)}
        changed_props = convert_properties_to :db, changed_props
        _persisted_node.update_props(changed_props)
        @changed_attributes.clear
      end
    end

    def _create_node(*args)
      session = self.class.neo4j_session
      props = args[0] if args[0].is_a?(Hash)
      labels = self.class.mapped_label_names
      session.create_node(props, labels)
    end

    # @return [Hash] all defined and none nil properties
    def props
      attributes.reject{|k,v| v.nil?}.symbolize_keys
    end

    # @return true if the attributes hash has been frozen
    def frozen?
      freeze_if_deleted
      @attributes.frozen?
    end

    def freeze
      @attributes.freeze
      self
    end

    def freeze_if_deleted
      unless new_record?
        # TODO - Neo4j::IdentityMap.remove_node_by_id(neo_id)
        unless self.class.load_entity(neo_id)
          @_deleted = true
          freeze
        end
      end
    end

    def reload
      return self if new_record?
      @changed_attributes && @changed_attributes.clear
      unless reload_from_database
        @_deleted = true
        freeze
      end
      self
    end

    def reload_from_database
      # TODO - Neo4j::IdentityMap.remove_node_by_id(neo_id)
      if reloaded = self.class.load_entity(neo_id)
        send(:attributes=, reloaded.attributes)
      end
      reloaded
    end

    # Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
    # If saving fails because the resource is invalid then false will be returned.
    def update(attributes)
      self.attributes = attributes
      save
    end
    alias_method :update_attributes, :update

    # Same as {#update_attributes}, but raises an exception if saving fails.
    def update!(attributes)
      self.attributes = attributes
      save!
    end
    alias_method :update_attributes!, :update!

    module ClassMethods
      # Creates a saves a new node
      # @param [Hash] props the properties the new node should have
      def create(props = {})
        new(props).tap do |obj|
          obj.save
        end
      end

      # Same as #create, but raises an error if there is a problem during save.
      def create!(*args)
        new(*args).tap do |o|
          yield o if block_given?
          o.save!
        end
      end

      def load_entity(id)
        Neo4j::Node.load(id)
      end

    end

  end

end
