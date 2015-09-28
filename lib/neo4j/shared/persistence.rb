module Neo4j::Shared
  module Persistence
    extend ActiveSupport::Concern

    USES_CLASSNAME = []

    # @return [Hash] Given a node's state, will call the appropriate `props_for_{action}` method.
    def props_for_persistence
      _persisted_obj ? props_for_update : props_for_create
    end

    def update_model
      return if !changed_attributes || changed_attributes.empty?
      _persisted_obj.update_props(props_for_update)
      changed_attributes.clear
    end

    # Returns a hash containing:
    # * All properties and values for insertion in the database
    # * A `uuid` (or equivalent) key and value
    # * A `_classname` property, if one is to be set
    # * Timestamps, if the class is set to include them.
    # Note that the UUID is added to the hash but is not set on the node.
    # The timestamps, by comparison, are set on the node prior to addition in this hash.
    # @return [Hash]
    def props_for_create
      inject_timestamps!
      converted_props = props_for_db(props)
      inject_classname!(converted_props)
      inject_defaults!(converted_props)
      return converted_props unless self.class.respond_to?(:default_property_values)
      inject_primary_key!(converted_props)
    end

    # @return [Hash] Properties and values, type-converted and timestamped for the database.
    def props_for_update
      update_magic_properties
      changed_props = attributes.select { |k, _| changed_attributes.include?(k) }
      changed_props.symbolize_keys!
      props_for_db(changed_props)
      inject_defaults!(changed_props)
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
      apply_default_values
      result = _persisted_obj ? update_model : create_model
      if result == false
        Neo4j::Transaction.current.failure if Neo4j::Transaction.current
        false
      else
        true
      end
    rescue => e
      Neo4j::Transaction.current.failure if Neo4j::Transaction.current
      raise e
    ensure
      @_create_or_updating = nil
    end

    def apply_default_values
      return if self.class.declared_property_defaults.empty?
      self.class.declared_property_defaults.each_pair do |key, value|
        self.send("#{key}=", value) if self.send(key).nil?
      end
    end

    # Returns +true+ if the record is persisted, i.e. it's not a new record and it was not destroyed
    def persisted?
      !new_record? && !destroyed?
    end

    # Returns +true+ if the record hasn't been saved to Neo4j yet.
    def new_record?
      !_persisted_obj
    end

    alias_method :new?, :new_record?

    def destroy
      freeze
      _persisted_obj && _persisted_obj.del
      @_deleted = true
    end

    def exist?
      _persisted_obj && _persisted_obj.exist?
    end

    # Returns +true+ if the object was destroyed.
    def destroyed?
      @_deleted
    end

    # @return [Hash] all defined and none nil properties
    def props
      attributes.reject { |_, v| v.nil? }.symbolize_keys
    end

    # @return true if the attributes hash has been frozen
    def frozen?
      @attributes.frozen?
    end

    def freeze
      @attributes.freeze
      self
    end

    def reload
      return self if new_record?
      association_proxy_cache.clear if respond_to?(:association_proxy_cache)
      changed_attributes && changed_attributes.clear
      unless reload_from_database
        @_deleted = true
        freeze
      end
      self
    end

    def reload_from_database
      # TODO: - Neo4j::IdentityMap.remove_node_by_id(neo_id)
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

    def props_for_db(props_hash)
      self.class.declared_property_manager.convert_properties_to(self, :db, props_hash)
    end

    def model_cache_key
      self.class.model_name.cache_key
    end

    def update_magic_properties
      self.updated_at = DateTime.now if respond_to?(:updated_at=) && (updated_at.nil? || (changed? && !updated_at_changed?))
    end

    # Inserts the _classname property into an object's properties during object creation.
    def inject_classname!(props, check_version = true)
      props[:_classname] = self.class.name if self.class.cached_class?(check_version)
    end

    def set_classname(props, check_version = true)
      warning = 'This method has been replaced with `inject_classname!` and will be removed in a future version'.freeze
      ActiveSupport::Deprecation.warn warning, caller
      inject_classname!(props, check_version)
    end

    def inject_timestamps!
      now = DateTime.now
      self.created_at ||= now if respond_to?(:created_at=)
      self.updated_at ||= now if respond_to?(:updated_at=)
    end

    def inject_defaults!(properties)
      self.class.declared_property_manager.declared_property_defaults.each_pair do |k, v|
        properties[k.to_sym] = v if send(k).nil?
      end
      properties
    end

    def set_timestamps
      warning = 'This method has been replaced with `inject_timestamps!` and will be removed in a future version'.freeze
      ActiveSupport::Deprecation.warn warning, caller
      inject_timestamps!
    end

    module ClassMethods
      # Determines whether a model should insert a _classname property. This can be used to override the automatic matching of returned
      # objects to models.
      def cached_class?(check_version = true)
        uses_classname? || (!!Neo4j::Config[:cache_class_names] && (check_version ? neo4j_session.version < '2.1.5' : true))
      end

      # @return [Boolean] status of whether this model will add a _classname property
      def uses_classname?
        Neo4j::Shared::Persistence::USES_CLASSNAME.include?(self.name)
      end

      # Adds this model to the USES_CLASSNAME array. When new rels/nodes are created, a _classname property will be added. This will override the
      # automatic matching of label/rel type to model.
      #
      # You'd want to do this if you have multiple models for the same label or relationship type. When it comes to labels, there isn't really any
      # reason to do this because you can have multiple labels; on the other hand, an argument can be made for doing this with relationships since
      # rel type is a bit more restrictive.
      #
      # It could also be speculated that there's a slight performance boost to using _classname since the gem immediately knows what model is responsible
      # for a returned object. At the same time, it is a bit restrictive and changing it can be a bit of a PITA. Use carefully!
      def set_classname
        Neo4j::Shared::Persistence::USES_CLASSNAME << self.name
      end

      # Removes this model from the USES_CLASSNAME array. When new rels/nodes are create, no _classname property will be injected. Upon returning of
      # the object from the database, it will be matched to a model using its relationship type or labels.
      def unset_classname
        Neo4j::Shared::Persistence::USES_CLASSNAME.delete self.name
      end
    end
  end
end
