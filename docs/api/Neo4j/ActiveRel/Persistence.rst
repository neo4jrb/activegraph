Persistence
===========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   Persistence/RelInvalidError

   Persistence/ModelClassInvalidError

   Persistence/RelCreateFailedError

   

   

   

   

   

   

   

   

   

   Persistence/ClassMethods

   

   

   

   

   

   Persistence/QueryFactory




Constants
---------





Files
-----



  * `lib/neo4j/active_rel/persistence.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/persistence.rb#L2>`_

  * `lib/neo4j/active_rel/persistence/query_factory.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/persistence/query_factory.rb#L1>`_





Methods
-------



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



.. _`Neo4j/ActiveRel/Persistence#concurrent_increment!`:

**#concurrent_increment!**
  Increments concurrently a numeric attribute by a centain amount

  .. code-block:: ruby

     def concurrent_increment!(attribute, by = 1)
       query_rel = Neo4j::Session.query.match('()-[n]-()').where(n: {neo_id: neo_id})
       increment_by_query! query_rel, attribute, by
     end



.. _`Neo4j/ActiveRel/Persistence#create_method`:

**#create_method**
  

  .. code-block:: ruby

     def create_method
       self.class.create_method
     end



.. _`Neo4j/ActiveRel/Persistence#create_model`:

**#create_model**
  

  .. code-block:: ruby

     def create_model
       validate_node_classes!
       rel = _create_rel
       return self unless rel.respond_to?(:props)
       init_on_load(rel, from_node, to_node, @rel_type)
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



.. _`Neo4j/ActiveRel/Persistence#cypher_identifier`:

**#cypher_identifier**
  

  .. code-block:: ruby

     def cypher_identifier
       @cypher_identifier || :rel
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
       @_deleted
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



.. _`Neo4j/ActiveRel/Persistence#from_node_identifier`:

**#from_node_identifier**
  

  .. code-block:: ruby

     def from_node_identifier
       @from_node_identifier || :from_node
     end



.. _`Neo4j/ActiveRel/Persistence#from_node_identifier=`:

**#from_node_identifier=**
  

  .. code-block:: ruby

     def from_node_identifier=(id)
       @from_node_identifier = id.to_sym
     end



.. _`Neo4j/ActiveRel/Persistence#frozen?`:

**#frozen?**
  

  .. code-block:: ruby

     def frozen?
       @attributes.frozen?
     end



.. _`Neo4j/ActiveRel/Persistence#increment`:

**#increment**
  Increments a numeric attribute by a centain amount

  .. code-block:: ruby

     def increment(attribute, by = 1)
       self[attribute] ||= 0
       self[attribute] += by
       self
     end



.. _`Neo4j/ActiveRel/Persistence#increment!`:

**#increment!**
  Convenience method to increment numeric attribute and #save at the same time

  .. code-block:: ruby

     def increment!(attribute, by = 1)
       increment(attribute, by).update_attribute(attribute, self[attribute])
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
  * Timestamps, if the class is set to include them.
  Note that the UUID is added to the hash but is not set on the node.
  The timestamps, by comparison, are set on the node prior to addition in this hash.

  .. code-block:: ruby

     def props_for_create
       inject_timestamps!
       props_with_defaults = inject_defaults!(props)
       converted_props = props_for_db(props_with_defaults)
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
       inject_defaults!(changed_props)
       props_for_db(changed_props)
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
       reloaded = self.class.load_entity(neo_id)
       reloaded ? init_on_reload(reloaded._persisted_obj) : nil
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
       save(*args) or fail(RelInvalidError, inspect) # rubocop:disable Style/AndOr
     end



.. _`Neo4j/ActiveRel/Persistence#to_node_identifier`:

**#to_node_identifier**
  

  .. code-block:: ruby

     def to_node_identifier
       @to_node_identifier || :to_node
     end



.. _`Neo4j/ActiveRel/Persistence#to_node_identifier=`:

**#to_node_identifier=**
  

  .. code-block:: ruby

     def to_node_identifier=(id)
       @to_node_identifier = id.to_sym
     end



.. _`Neo4j/ActiveRel/Persistence#touch`:

**#touch**
  

  .. code-block:: ruby

     def touch
       fail 'Cannot touch on a new record object' unless persisted?
       update_attribute!(:updated_at, Time.now) if respond_to?(:updated_at=)
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





