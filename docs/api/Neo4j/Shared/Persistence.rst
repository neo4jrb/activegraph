Persistence
===========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   Persistence/ClassMethods




Constants
---------



  * USES_CLASSNAME



Files
-----



  * `lib/neo4j/shared/persistence.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/persistence.rb#L2>`_





Methods
-------



.. _`Neo4j/Shared/Persistence#apply_default_values`:

**#apply_default_values**
  

  .. hidden-code-block:: ruby

     def apply_default_values
       return if self.class.declared_property_defaults.empty?
       self.class.declared_property_defaults.each_pair do |key, value|
         self.send("#{key}=", value) if self.send(key).nil?
       end
     end



.. _`Neo4j/Shared/Persistence#cache_key`:

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



.. _`Neo4j/Shared/Persistence#create_or_update`:

**#create_or_update**
  

  .. hidden-code-block:: ruby

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



.. _`Neo4j/Shared/Persistence#destroy`:

**#destroy**
  

  .. hidden-code-block:: ruby

     def destroy
       freeze
       _persisted_obj && _persisted_obj.del
       @_deleted = true
     end



.. _`Neo4j/Shared/Persistence#destroyed?`:

**#destroyed?**
  Returns +true+ if the object was destroyed.

  .. hidden-code-block:: ruby

     def destroyed?
       !!@_deleted
     end



.. _`Neo4j/Shared/Persistence#exist?`:

**#exist?**
  

  .. hidden-code-block:: ruby

     def exist?
       _persisted_obj && _persisted_obj.exist?
     end



.. _`Neo4j/Shared/Persistence#freeze`:

**#freeze**
  

  .. hidden-code-block:: ruby

     def freeze
       @attributes.freeze
       self
     end



.. _`Neo4j/Shared/Persistence#frozen?`:

**#frozen?**
  

  .. hidden-code-block:: ruby

     def frozen?
       @attributes.frozen?
     end



.. _`Neo4j/Shared/Persistence#new?`:

**#new?**
  Returns +true+ if the record hasn't been saved to Neo4j yet.

  .. hidden-code-block:: ruby

     def new_record?
       !_persisted_obj
     end



.. _`Neo4j/Shared/Persistence#new_record?`:

**#new_record?**
  Returns +true+ if the record hasn't been saved to Neo4j yet.

  .. hidden-code-block:: ruby

     def new_record?
       !_persisted_obj
     end



.. _`Neo4j/Shared/Persistence#persisted?`:

**#persisted?**
  Returns +true+ if the record is persisted, i.e. it's not a new record and it was not destroyed

  .. hidden-code-block:: ruby

     def persisted?
       !new_record? && !destroyed?
     end



.. _`Neo4j/Shared/Persistence#props`:

**#props**
  

  .. hidden-code-block:: ruby

     def props
       attributes.reject { |_, v| v.nil? }.symbolize_keys
     end



.. _`Neo4j/Shared/Persistence#reload`:

**#reload**
  

  .. hidden-code-block:: ruby

     def reload
       return self if new_record?
       association_proxy_cache.clear
       changed_attributes && changed_attributes.clear
       unless reload_from_database
         @_deleted = true
         freeze
       end
       self
     end



.. _`Neo4j/Shared/Persistence#reload_from_database`:

**#reload_from_database**
  

  .. hidden-code-block:: ruby

     def reload_from_database
       # TODO: - Neo4j::IdentityMap.remove_node_by_id(neo_id)
       if reloaded = self.class.load_entity(neo_id)
         send(:attributes=, reloaded.attributes)
       end
       reloaded
     end



.. _`Neo4j/Shared/Persistence#update`:

**#update**
  Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  If saving fails because the resource is invalid then false will be returned.

  .. hidden-code-block:: ruby

     def update(attributes)
       self.attributes = process_attributes(attributes)
       save
     end



.. _`Neo4j/Shared/Persistence#update!`:

**#update!**
  Same as {#update_attributes}, but raises an exception if saving fails.

  .. hidden-code-block:: ruby

     def update!(attributes)
       self.attributes = process_attributes(attributes)
       save!
     end



.. _`Neo4j/Shared/Persistence#update_attribute`:

**#update_attribute**
  Convenience method to set attribute and #save at the same time

  .. hidden-code-block:: ruby

     def update_attribute(attribute, value)
       send("#{attribute}=", value)
       self.save
     end



.. _`Neo4j/Shared/Persistence#update_attribute!`:

**#update_attribute!**
  Convenience method to set attribute and #save! at the same time

  .. hidden-code-block:: ruby

     def update_attribute!(attribute, value)
       send("#{attribute}=", value)
       self.save!
     end



.. _`Neo4j/Shared/Persistence#update_attributes`:

**#update_attributes**
  Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  If saving fails because the resource is invalid then false will be returned.

  .. hidden-code-block:: ruby

     def update(attributes)
       self.attributes = process_attributes(attributes)
       save
     end



.. _`Neo4j/Shared/Persistence#update_attributes!`:

**#update_attributes!**
  Same as {#update_attributes}, but raises an exception if saving fails.

  .. hidden-code-block:: ruby

     def update!(attributes)
       self.attributes = process_attributes(attributes)
       save!
     end



.. _`Neo4j/Shared/Persistence#update_model`:

**#update_model**
  

  .. hidden-code-block:: ruby

     def update_model
       return if !changed_attributes || changed_attributes.empty?
     
       changed_props = attributes.select { |k, _| changed_attributes.include?(k) }
       changed_props = self.class.declared_property_manager.convert_properties_to(self, :db, changed_props)
       _persisted_obj.update_props(changed_props)
       changed_attributes.clear
     end





