Persistence
===========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   Persistence/RelInvalidError

   Persistence/ModelClassInvalidError

   Persistence/RelCreateFailedError

   

   

   

   Persistence/ClassMethods

   

   

   

   

   

   

   




Constants
---------



  * N1_N2_STRING

  * ACTIVEREL_NODE_MATCH_STRING

  * USES_CLASSNAME



Files
-----



  * `lib/neo4j/active_rel/persistence.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/persistence.rb#L2>`_





Methods
-------



.. _`Neo4j/ActiveRel/Persistence#_active_record_destroyed_behavior?`:

**#_active_record_destroyed_behavior?**
  

  .. code-block:: ruby

     def _active_record_destroyed_behavior?
       fail 'Remove this workaround in 6.0.0' if Neo4j::VERSION >= '6.0.0'
     
       !!Neo4j::Config[:_active_record_destroyed_behavior]
     end



.. _`Neo4j/ActiveRel/Persistence#_destroyed_double_check?`:

**#_destroyed_double_check?**
  These two methods should be removed in 6.0.0

  .. code-block:: ruby

     def _destroyed_double_check?
       if _active_record_destroyed_behavior?
         false
       else
         (!new_record? && !exist?)
       end
     end



.. _`Neo4j/ActiveRel/Persistence#apply_default_values`:

**#apply_default_values**
  

  .. code-block:: ruby

     def apply_default_values
       return if self.class.declared_property_defaults.empty?
       self.class.declared_property_defaults.each_pair do |key, value|
         self.send("#{key}=", value) if self.send(key).nil?
       end
     end



.. _`Neo4j/ActiveRel/Persistence#cache_key`:

**#cache_key**
  

  .. code-block:: ruby

     def cache_key
       if self.new_record?
         "#{model_cache_key}/new"
       elsif self.respond_to?(:updated_at) && !self.updated_at.blank?
         "#{model_cache_key}/#{neo_id}-#{self.updated_at.utc.to_s(:number)}"
       else
         "#{model_cache_key}/#{neo_id}"
       end
     end



.. _`Neo4j/ActiveRel/Persistence#create_model`:

**#create_model**
  

  .. code-block:: ruby

     def create_model
       validate_node_classes!
       rel = _create_rel(from_node, to_node, props_for_create)
       return self unless rel.respond_to?(:_persisted_obj)
       init_on_load(rel._persisted_obj, from_node, to_node, @rel_type)
       true
     end



.. _`Neo4j/ActiveRel/Persistence#create_or_update`:

**#create_or_update**
  

  .. code-block:: ruby

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



.. _`Neo4j/ActiveRel/Persistence#destroy`:

**#destroy**
  

  .. code-block:: ruby

     def destroy
       freeze
       _persisted_obj && _persisted_obj.del
       @_deleted = true
     end



.. _`Neo4j/ActiveRel/Persistence#destroyed?`:

**#destroyed?**
  Returns +true+ if the object was destroyed.

  .. code-block:: ruby

     def destroyed?
       @_deleted || _destroyed_double_check?
     end



.. _`Neo4j/ActiveRel/Persistence#exist?`:

**#exist?**
  

  .. code-block:: ruby

     def exist?
       _persisted_obj && _persisted_obj.exist?
     end



.. _`Neo4j/ActiveRel/Persistence#freeze`:

**#freeze**
  

  .. code-block:: ruby

     def freeze
       @attributes.freeze
       self
     end



.. _`Neo4j/ActiveRel/Persistence#frozen?`:

**#frozen?**
  

  .. code-block:: ruby

     def frozen?
       @attributes.frozen?
     end



.. _`Neo4j/ActiveRel/Persistence#new?`:

**#new?**
  Returns +true+ if the record hasn't been saved to Neo4j yet.

  .. code-block:: ruby

     def new_record?
       !_persisted_obj
     end



.. _`Neo4j/ActiveRel/Persistence#new_record?`:

**#new_record?**
  Returns +true+ if the record hasn't been saved to Neo4j yet.

  .. code-block:: ruby

     def new_record?
       !_persisted_obj
     end



.. _`Neo4j/ActiveRel/Persistence#persisted?`:

**#persisted?**
  Returns +true+ if the record is persisted, i.e. it's not a new record and it was not destroyed

  .. code-block:: ruby

     def persisted?
       !new_record? && !destroyed?
     end



.. _`Neo4j/ActiveRel/Persistence#props`:

**#props**
  

  .. code-block:: ruby

     def props
       attributes.reject { |_, v| v.nil? }.symbolize_keys
     end



.. _`Neo4j/ActiveRel/Persistence#props_for_create`:

**#props_for_create**
  Returns a hash containing:
  * All properties and values for insertion in the database
  * A `uuid` (or equivalent) key and value
  * A `_classname` property, if one is to be set
  * Timestamps, if the class is set to include them.
  Note that the UUID is added to the hash but is not set on the node.
  The timestamps, by comparison, are set on the node prior to addition in this hash.

  .. code-block:: ruby

     def props_for_create
       inject_timestamps!
       converted_props = props_for_db(props)
       inject_classname!(converted_props)
       inject_defaults!(converted_props)
       return converted_props unless self.class.respond_to?(:default_property_values)
       inject_primary_key!(converted_props)
     end



.. _`Neo4j/ActiveRel/Persistence#props_for_persistence`:

**#props_for_persistence**
  

  .. code-block:: ruby

     def props_for_persistence
       _persisted_obj ? props_for_update : props_for_create
     end



.. _`Neo4j/ActiveRel/Persistence#props_for_update`:

**#props_for_update**
  

  .. code-block:: ruby

     def props_for_update
       update_magic_properties
       changed_props = attributes.select { |k, _| changed_attributes.include?(k) }
       changed_props.symbolize_keys!
       props_for_db(changed_props)
       inject_defaults!(changed_props)
     end



.. _`Neo4j/ActiveRel/Persistence#reload`:

**#reload**
  

  .. code-block:: ruby

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



.. _`Neo4j/ActiveRel/Persistence#reload_from_database`:

**#reload_from_database**
  

  .. code-block:: ruby

     def reload_from_database
       # TODO: - Neo4j::IdentityMap.remove_node_by_id(neo_id)
       if reloaded = self.class.load_entity(neo_id)
         send(:attributes=, reloaded.attributes)
       end
       reloaded
     end



.. _`Neo4j/ActiveRel/Persistence#save`:

**#save**
  

  .. code-block:: ruby

     def save(*)
       create_or_update
     end



.. _`Neo4j/ActiveRel/Persistence#save!`:

**#save!**
  

  .. code-block:: ruby

     def save!(*args)
       fail RelInvalidError, self unless save(*args)
     end



.. _`Neo4j/ActiveRel/Persistence#update`:

**#update**
  Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  If saving fails because the resource is invalid then false will be returned.

  .. code-block:: ruby

     def update(attributes)
       self.attributes = process_attributes(attributes)
       save
     end



.. _`Neo4j/ActiveRel/Persistence#update!`:

**#update!**
  Same as {#update_attributes}, but raises an exception if saving fails.

  .. code-block:: ruby

     def update!(attributes)
       self.attributes = process_attributes(attributes)
       save!
     end



.. _`Neo4j/ActiveRel/Persistence#update_attribute`:

**#update_attribute**
  Convenience method to set attribute and #save at the same time

  .. code-block:: ruby

     def update_attribute(attribute, value)
       send("#{attribute}=", value)
       self.save
     end



.. _`Neo4j/ActiveRel/Persistence#update_attribute!`:

**#update_attribute!**
  Convenience method to set attribute and #save! at the same time

  .. code-block:: ruby

     def update_attribute!(attribute, value)
       send("#{attribute}=", value)
       self.save!
     end



.. _`Neo4j/ActiveRel/Persistence#update_attributes`:

**#update_attributes**
  Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  If saving fails because the resource is invalid then false will be returned.

  .. code-block:: ruby

     def update(attributes)
       self.attributes = process_attributes(attributes)
       save
     end



.. _`Neo4j/ActiveRel/Persistence#update_attributes!`:

**#update_attributes!**
  Same as {#update_attributes}, but raises an exception if saving fails.

  .. code-block:: ruby

     def update!(attributes)
       self.attributes = process_attributes(attributes)
       save!
     end



.. _`Neo4j/ActiveRel/Persistence#update_model`:

**#update_model**
  

  .. code-block:: ruby

     def update_model
       return if !changed_attributes || changed_attributes.empty?
       _persisted_obj.update_props(props_for_update)
       changed_attributes.clear
     end





