module Neo4j::Shared
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
      update_magic_properties
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
      unless save(*args)
        raise RecordInvalidError.new(self)
      end
    end

    def update_model
      if changed_attributes && !changed_attributes.empty?
        changed_props = attributes.select{|k,v| changed_attributes.include?(k)}
        changed_props = convert_properties_to :db, changed_props
        _persisted_obj.update_props(changed_props)
        changed_attributes.clear
      end
    end


    # Convenience method to set attribute and #save at the same time
    # @param [Symbol, String] attribute of the attribute to update
    # @param [Object] value to set
    def update_attribute(attribute, value)
      send("#{attribute}=", value)
      self.save
    end

    # Convenience method to set attribute and #save! at the same time
    # @param [Symbol, String] attribute of the attribute to update
    # @param [Object] value to set
    def update_attribute!(attribute, value)
      send("#{attribute}=", value)
      self.save!
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

    # Returns +true+ if the record is persisted, i.e. it’s not a new record and it was not destroyed
    def persisted?
      !new_record? && !destroyed?
    end

    # Returns +true+ if the record hasn't been saved to Neo4j yet.
    def new_record?
      !_persisted_obj
    end

    alias :new? :new_record?

    def destroy
      _persisted_obj && _persisted_obj.del
      @_deleted = true
    end

    def exist?
      _persisted_obj && _persisted_obj.exist?
    end

    # Returns +true+ if the object was destroyed.
    def destroyed?
      @_deleted || (!new_record? && !exist?)
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
      changed_attributes && changed_attributes.clear
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
      self.attributes = process_attributes(attributes)
      save
    end
    alias_method :update_attributes, :update

    # Same as {#update_attributes}, but raises an exception if saving fails.
    def update!(attributes)
      self.attributes = process_attributes(attributes)
      save!
    end
    alias_method :update_attributes!, :update!

    def cache_key
      if self.new_record?
        "#{model_cache_key}/new"
      elsif self.respond_to?(:updated_at) && !self.updated_at.blank?
        "#{model_cache_key}/#{neo_id}-#{self.updated_at.utc.to_s(:number)}"
      else
        "#{model_cache_key}/#{neo_id}"
      end
    end

    private

    def model_cache_key
      self.class.model_name.cache_key
    end

    def create_magic_properties
    end

    def update_magic_properties
      self.updated_at = DateTime.now if respond_to?(:updated_at=) && changed?
    end

    def set_classname(props)
      props[:_classname] = self.class.name if self.class.cached_class?
    end

    def set_timestamps
      self.created_at = DateTime.now if respond_to?(:created_at=)
      self.updated_at = self.created_at if respond_to?(:updated_at=)
    end
  end
end