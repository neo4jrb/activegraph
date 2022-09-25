module ActiveGraph::Shared
  # rubocop:disable Metrics/ModuleLength
  module Persistence
    # rubocop:enable Metrics/ModuleLength
    extend ActiveSupport::Concern

    # @return [Hash] Given a node's state, will call the appropriate `props_for_{action}` method.
    def props_for_persistence
      _persisted_obj ? props_for_update : props_for_create
    end

    def update_model
      return if skip_update?
      props = props_for_update
      neo4j_query(query_as(:n).set(n: props))
      _persisted_obj.properties.merge!(props)
      changed_attributes_clear!
    end

    def skip_update?
      changed_attributes.blank?
    end

    # Returns a hash containing:
    # * All properties and values for insertion in the database
    # * A `uuid` (or equivalent) key and value
    # * Timestamps, if the class is set to include them.
    # Note that the UUID is added to the hash but is not set on the node.
    # The timestamps, by comparison, are set on the node prior to addition in this hash.
    # @return [Hash]
    def props_for_create
      inject_timestamps!
      props_with_defaults = inject_defaults!(props)
      converted_props = props_for_db(props_with_defaults)
      return converted_props unless self.class.respond_to?(:default_property_values)
      inject_primary_key!(converted_props)
    end

    # @return [Hash] Properties and values, type-converted and timestamped for the database.
    def props_for_update
      update_magic_properties
      changed_props = attributes.select { |k, _| changed_attributes.include?(k) }
      changed_props.symbolize_keys!
      inject_defaults!(changed_props)
      props_for_db(changed_props)
    end

    # Increments a numeric attribute by a centain amount
    # @param [Symbol, String] attribute name of the attribute to increment
    # @param [Integer, Float] by amount to increment
    def increment(attribute, by = 1)
      self[attribute] ||= 0
      self[attribute] += by
      self
    end

    # Convenience method to increment numeric attribute and #save at the same time
    # @param [Symbol, String] attribute name of the attribute to increment
    # @param [Integer, Float] by amount to increment
    def increment!(attribute, by = 1)
      increment(attribute, by).update_attribute(attribute, self[attribute])
    end

    # Increments concurrently a numeric attribute by a centain amount
    # @param [Symbol, String] _attribute name of the attribute to increment
    # @param [Integer, Float] _by amount to increment
    def concurrent_increment!(_attribute, _by = 1)
      fail 'not_implemented'
    end

    # Convenience method to set attribute and #save at the same time
    # @param [Symbol, String] attribute of the attribute to update
    # @param [Object] value to set
    def update_attribute(attribute, value)
      write_attribute(attribute, value)
      self.save
    end

    # Convenience method to set attribute and #save! at the same time
    # @param [Symbol, String] attribute of the attribute to update
    # @param [Object] value to set
    def update_attribute!(attribute, value)
      write_attribute(attribute, value)
      self.save!
    end

    def create_or_update
      # since the same model can be created or updated twice from a relationship we have to have this guard
      @_create_or_updating = true
      apply_default_values
      result = _persisted_obj ? update_model : create_model

      ActiveGraph::Base.transaction(&:rollback) if result == false

      result != false
    ensure
      @_create_or_updating = nil
    end

    def apply_default_values
      return if self.class.declared_property_defaults.empty?
      self.class.declared_property_defaults.each_pair do |key, value|
        self.send("#{key}=", value.respond_to?(:call) ? value.call : value) if self.send(key).nil?
      end
    end

    def touch(*names)
      fail 'Cannot touch on a new record object' unless persisted?
      attributes = [:updated_at].concat(names)
      current_time = Time.now
      changes = {}
      attributes.each do |column|
        column = column.to_s
        changes[column] = write_attribute(column, current_time) if respond_to?((column + '=').to_sym)
      end
      save!
    end

    # Returns +true+ if the record is persisted, i.e. it's not a new record and it was not destroyed
    def persisted?
      !new_record? && !destroyed?
    end

    # Returns +true+ if the record hasn't been saved to Neo4j yet.
    def new_record?
      !_persisted_obj
    end

    alias new? new_record?

    def destroy
      freeze

      destroy_query.exec if _persisted_obj

      @_deleted = true

      self
    end

    def exist?
      return if !_persisted_obj

      neo4j_query(query_as(:n).return('ID(n)')).any?
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
      changed_attributes_clear!
      unless reload_from_database
        @_deleted = true
        freeze
      end
      self
    end

    def reload_from_database
      reloaded = self.class.load_entity(neo_id)
      reloaded ? init_on_reload(reloaded._persisted_obj) : nil
    end

    # Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
    # If saving fails because the resource is invalid then false will be returned.
    def update(attributes)
      ActiveGraph::Base.transaction do |tx|
        self.attributes = process_attributes(attributes)
        saved = save
        tx.rollback unless saved
        saved
      end
    end
    alias update_attributes update

    def update_db_property(field, value)
      update_db_properties(field => value)
      true
    end
    alias update_column update_db_property

    def update_db_properties(hash)
      fail ::ActiveGraph::Error, 'can not update on a new record object' unless persisted?
      ActiveGraph::Base.transaction do
        db_values = props_for_db(hash)
        neo4j_query(query_as(:n).set(n: db_values))
        db_values.each_pair { |k, v| self.public_send(:"#{k}=", v) }
        _persisted_obj.properties.merge!(db_values)
        changed_attributes_selective_clear!(db_values)
        true
      end
    end
    alias update_columns update_db_properties

    # Same as {#update_attributes}, but raises an exception if saving fails.
    def update!(attributes)
      ActiveGraph::Base.transaction do
        self.attributes = process_attributes(attributes)
        save!
      end
    end
    alias update_attributes! update!

    def cache_key
      if self.new_record?
        "#{model_cache_key}/new"
      elsif self.respond_to?(:updated_at) && !self.updated_at.blank?
        "#{model_cache_key}/#{neo_id}-#{self.updated_at.utc.to_s(:number)}"
      else
        "#{model_cache_key}/#{neo_id}"
      end
    end

    protected

    def increment_by_query!(match_query, attribute, by, element_name = :n)
      new_attribute = match_query.with(element_name)
                                 .set("#{element_name}.`#{attribute}` = COALESCE(#{element_name}.`#{attribute}`, 0) + $by")
                                 .params(by: by).limit(1)
                                 .pluck("#{element_name}.`#{attribute}`").first
      return false unless new_attribute
      self[attribute] = new_attribute

      if defined? ActiveModel::ForcedMutationTracker
        # with ActiveModel 6.0.0 set_attribute_was is removed
        # so we mark attribute's previous value using attr_will_change method
        clear_attribute_change(attribute)
      else
        set_attribute_was(attribute, new_attribute)
      end
      true
    end

    private

    def props_for_db(props_hash)
      self.class.declared_properties.convert_properties_to(self, :db, props_hash)
    end

    def model_cache_key
      self.class.model_name.cache_key
    end

    def update_magic_properties
      self.updated_at = DateTime.now if respond_to?(:updated_at=) && (updated_at.nil? || (changed? && !updated_at_changed?))
    end

    def inject_timestamps!
      now = DateTime.now
      self.created_at ||= now if respond_to?(:created_at=)
      self.updated_at ||= now if respond_to?(:updated_at=)
    end

    def set_timestamps
      warning = 'This method has been replaced with `inject_timestamps!` and will be removed in a future version'.freeze
      ActiveSupport::Deprecation.warn warning, caller
      inject_timestamps!
    end
  end
end
