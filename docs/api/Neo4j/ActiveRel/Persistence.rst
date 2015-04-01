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


.. _Persistence_cache_key:

**#cache_key**
  

  .. hidden-code-block:: ruby

     def cache_key
       if self.new_record?
         "#{model_cache_key}/new"
       elsif self.respond_to?(:updated_at) && !self.updated_at.blank?
         "#{model_cache_key}/#{neo_id}-#{self.updated_at.utc.to_s(:number)}"
       else
         "#{model_cache_key}/#{neo_id}"
       end
     end


.. _Persistence_clear_association_cache:

**#clear_association_cache**
  

  .. hidden-code-block:: ruby

     def clear_association_cache; end


.. _Persistence_convert_properties_to:

**#convert_properties_to**
  

  .. hidden-code-block:: ruby

     def convert_properties_to(medium, properties)
       converter = medium == :ruby ? :to_ruby : :to_db
     
       properties.each_with_object({}) do |(attr, value), new_attributes|
         next new_attributes if skip_conversion?(attr, value)
         new_attributes[attr] = converted_property(primitive_type(attr.to_sym), value, converter)
       end
     end


.. _Persistence_create_model:

**#create_model**
  

  .. hidden-code-block:: ruby

     def create_model(*)
       validate_node_classes!
       create_magic_properties
       set_timestamps
       properties = convert_properties_to :db, props
       rel = _create_rel(from_node, to_node, properties)
       return self unless rel.respond_to?(:_persisted_obj)
       init_on_load(rel._persisted_obj, from_node, to_node, @rel_type)
       true
     end


.. _Persistence_create_or_update:

**#create_or_update**
  

  .. hidden-code-block:: ruby

     def create_or_update
       # since the same model can be created or updated twice from a relationship we have to have this guard
       @_create_or_updating = true
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


.. _Persistence_destroy:

**#destroy**
  

  .. hidden-code-block:: ruby

     def destroy
       freeze
       _persisted_obj && _persisted_obj.del
       @_deleted = true
     end


.. _Persistence_destroyed?:

**#destroyed?**
  Returns +true+ if the object was destroyed.

  .. hidden-code-block:: ruby

     def destroyed?
       @_deleted || (!new_record? && !exist?)
     end


.. _Persistence_exist?:

**#exist?**
  

  .. hidden-code-block:: ruby

     def exist?
       _persisted_obj && _persisted_obj.exist?
     end


.. _Persistence_freeze:

**#freeze**
  

  .. hidden-code-block:: ruby

     def freeze
       @attributes.freeze
       self
     end


.. _Persistence_frozen?:

**#frozen?**
  

  .. hidden-code-block:: ruby

     def frozen?
       @attributes.frozen?
     end


.. _Persistence_new?:

**#new?**
  Returns +true+ if the record hasn't been saved to Neo4j yet.

  .. hidden-code-block:: ruby

     def new_record?
       !_persisted_obj
     end


.. _Persistence_new_record?:

**#new_record?**
  Returns +true+ if the record hasn't been saved to Neo4j yet.

  .. hidden-code-block:: ruby

     def new_record?
       !_persisted_obj
     end


.. _Persistence_persisted?:

**#persisted?**
  Returns +true+ if the record is persisted, i.e. it's not a new record and it was not destroyed

  .. hidden-code-block:: ruby

     def persisted?
       !new_record? && !destroyed?
     end


.. _Persistence_props:

**#props**
  

  .. hidden-code-block:: ruby

     def props
       attributes.reject { |_, v| v.nil? }.symbolize_keys
     end


.. _Persistence_reload:

**#reload**
  

  .. hidden-code-block:: ruby

     def reload
       return self if new_record?
       clear_association_cache
       changed_attributes && changed_attributes.clear
       unless reload_from_database
         @_deleted = true
         freeze
       end
       self
     end


.. _Persistence_reload_from_database:

**#reload_from_database**
  

  .. hidden-code-block:: ruby

     def reload_from_database
       # TODO: - Neo4j::IdentityMap.remove_node_by_id(neo_id)
       if reloaded = self.class.load_entity(neo_id)
         send(:attributes=, reloaded.attributes)
       end
       reloaded
     end


.. _Persistence_save:

**#save**
  

  .. hidden-code-block:: ruby

     def save(*)
       update_magic_properties
       create_or_update
     end


.. _Persistence_save!:

**#save!**
  

  .. hidden-code-block:: ruby

     def save!(*args)
       fail RelInvalidError, self unless save(*args)
     end


.. _Persistence_update:

**#update**
  Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  If saving fails because the resource is invalid then false will be returned.

  .. hidden-code-block:: ruby

     def update(attributes)
       self.attributes = process_attributes(attributes)
       save
     end


.. _Persistence_update!:

**#update!**
  Same as {#update_attributes}, but raises an exception if saving fails.

  .. hidden-code-block:: ruby

     def update!(attributes)
       self.attributes = process_attributes(attributes)
       save!
     end


.. _Persistence_update_attribute:

**#update_attribute**
  Convenience method to set attribute and #save at the same time

  .. hidden-code-block:: ruby

     def update_attribute(attribute, value)
       send("#{attribute}=", value)
       self.save
     end


.. _Persistence_update_attribute!:

**#update_attribute!**
  Convenience method to set attribute and #save! at the same time

  .. hidden-code-block:: ruby

     def update_attribute!(attribute, value)
       send("#{attribute}=", value)
       self.save!
     end


.. _Persistence_update_attributes:

**#update_attributes**
  Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  If saving fails because the resource is invalid then false will be returned.

  .. hidden-code-block:: ruby

     def update(attributes)
       self.attributes = process_attributes(attributes)
       save
     end


.. _Persistence_update_attributes!:

**#update_attributes!**
  Same as {#update_attributes}, but raises an exception if saving fails.

  .. hidden-code-block:: ruby

     def update!(attributes)
       self.attributes = process_attributes(attributes)
       save!
     end


.. _Persistence_update_model:

**#update_model**
  

  .. hidden-code-block:: ruby

     def update_model
       return if !changed_attributes || changed_attributes.empty?
     
       changed_props = attributes.select { |k, _| changed_attributes.include?(k) }
       changed_props = convert_properties_to :db, changed_props
       _persisted_obj.update_props(changed_props)
       changed_attributes.clear
     end





