Persistence
===========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   Persistence/RecordInvalidError

   

   

   

   

   

   

   

   

   Persistence/ClassMethods




Constants
---------





Files
-----



  * `lib/neo4j/active_node/persistence.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/persistence.rb#L2>`_





Methods
-------



.. _`Neo4j/ActiveNode/Persistence#_create_node`:

**#_create_node**
  TODO: This does not seem like it should be the responsibility of the node.
  Creates an unwrapped node in the database.

  .. code-block:: ruby

     def _create_node(node_props, labels = labels_for_create)
       self.class.neo4j_session.create_node(node_props, labels)
     end



.. _`Neo4j/ActiveNode/Persistence#apply_default_values`:

**#apply_default_values**
  

  .. code-block:: ruby

     def apply_default_values
       return if self.class.declared_property_defaults.empty?
       self.class.declared_property_defaults.each_pair do |key, value|
         self.send("#{key}=", value) if self.send(key).nil?
       end
     end



.. _`Neo4j/ActiveNode/Persistence#cache_key`:

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



.. _`Neo4j/ActiveNode/Persistence#concurrent_increment!`:

**#concurrent_increment!**
  Increments concurrently a numeric attribute by a centain amount

  .. code-block:: ruby

     def concurrent_increment!(attribute, by = 1)
       query_node = Neo4j::Session.query.match_nodes(n: neo_id)
       increment_by_query! query_node, attribute, by
     end



.. _`Neo4j/ActiveNode/Persistence#create_model`:

**#create_model**
  Creates a model with values matching those of the instance attributes and returns its id.

  .. code-block:: ruby

     def create_model
       node = _create_node(props_for_create)
       init_on_load(node, node.props)
       @deferred_nodes = nil
       true
     end



.. _`Neo4j/ActiveNode/Persistence#create_or_update`:

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



.. _`Neo4j/ActiveNode/Persistence#destroy`:

**#destroy**
  

  .. code-block:: ruby

     def destroy
       freeze
       _persisted_obj && _persisted_obj.del
       @_deleted = true
     end



.. _`Neo4j/ActiveNode/Persistence#destroyed?`:

**#destroyed?**
  Returns +true+ if the object was destroyed.

  .. code-block:: ruby

     def destroyed?
       @_deleted
     end



.. _`Neo4j/ActiveNode/Persistence#exist?`:

**#exist?**
  

  .. code-block:: ruby

     def exist?
       _persisted_obj && _persisted_obj.exist?
     end



.. _`Neo4j/ActiveNode/Persistence#freeze`:

**#freeze**
  

  .. code-block:: ruby

     def freeze
       @attributes.freeze
       self
     end



.. _`Neo4j/ActiveNode/Persistence#frozen?`:

**#frozen?**
  

  .. code-block:: ruby

     def frozen?
       @attributes.frozen?
     end



.. _`Neo4j/ActiveNode/Persistence#increment`:

**#increment**
  Increments a numeric attribute by a centain amount

  .. code-block:: ruby

     def increment(attribute, by = 1)
       self[attribute] ||= 0
       self[attribute] += by
       self
     end



.. _`Neo4j/ActiveNode/Persistence#increment!`:

**#increment!**
  Convenience method to increment numeric attribute and #save at the same time

  .. code-block:: ruby

     def increment!(attribute, by = 1)
       increment(attribute, by).update_attribute(attribute, self[attribute])
     end



.. _`Neo4j/ActiveNode/Persistence#inject_primary_key!`:

**#inject_primary_key!**
  As the name suggests, this inserts the primary key (id property) into the properties hash.
  The method called here, `default_property_values`, is a holdover from an earlier version of the gem. It does NOT
  contain the default values of properties, it contains the Default Property, which we now refer to as the ID Property.
  It will be deprecated and renamed in a coming refactor.

  .. code-block:: ruby

     def inject_primary_key!(converted_props)
       self.class.default_property_values(self).tap do |destination_props|
         destination_props.merge!(converted_props) if converted_props.is_a?(Hash)
       end
     end



.. _`Neo4j/ActiveNode/Persistence#labels_for_create`:

**#labels_for_create**
  

  .. code-block:: ruby

     def labels_for_create
       self.class.mapped_label_names
     end



.. _`Neo4j/ActiveNode/Persistence#new?`:

**#new?**
  Returns +true+ if the record hasn't been saved to Neo4j yet.

  .. code-block:: ruby

     def new_record?
       !_persisted_obj
     end



.. _`Neo4j/ActiveNode/Persistence#new_record?`:

**#new_record?**
  Returns +true+ if the record hasn't been saved to Neo4j yet.

  .. code-block:: ruby

     def new_record?
       !_persisted_obj
     end



.. _`Neo4j/ActiveNode/Persistence#persisted?`:

**#persisted?**
  Returns +true+ if the record is persisted, i.e. it's not a new record and it was not destroyed

  .. code-block:: ruby

     def persisted?
       !new_record? && !destroyed?
     end



.. _`Neo4j/ActiveNode/Persistence#props`:

**#props**
  

  .. code-block:: ruby

     def props
       attributes.reject { |_, v| v.nil? }.symbolize_keys
     end



.. _`Neo4j/ActiveNode/Persistence#props_for_create`:

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



.. _`Neo4j/ActiveNode/Persistence#props_for_persistence`:

**#props_for_persistence**
  

  .. code-block:: ruby

     def props_for_persistence
       _persisted_obj ? props_for_update : props_for_create
     end



.. _`Neo4j/ActiveNode/Persistence#props_for_update`:

**#props_for_update**
  

  .. code-block:: ruby

     def props_for_update
       update_magic_properties
       changed_props = attributes.select { |k, _| changed_attributes.include?(k) }
       changed_props.symbolize_keys!
       inject_defaults!(changed_props)
       props_for_db(changed_props)
     end



.. _`Neo4j/ActiveNode/Persistence#reload`:

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



.. _`Neo4j/ActiveNode/Persistence#reload_from_database`:

**#reload_from_database**
  

  .. code-block:: ruby

     def reload_from_database
       reloaded = self.class.load_entity(neo_id)
       reloaded ? init_on_reload(reloaded._persisted_obj) : nil
     end



.. _`Neo4j/ActiveNode/Persistence#save`:

**#save**
  Saves the model.
  
  If the model is new a record gets created in the database, otherwise the existing record gets updated.
  If perform_validation is true validations run.
  If any of them fail the action is cancelled and save returns false.
  If the flag is false validations are bypassed altogether.
  See ActiveRecord::Validations for more information.
  There's a series of callbacks associated with save.
  If any of the before_* callbacks return false the action is cancelled and save returns false.

  .. code-block:: ruby

     def save(*)
       cascade_save do
         association_proxy_cache.clear
         create_or_update
       end
     end



.. _`Neo4j/ActiveNode/Persistence#save!`:

**#save!**
  Persist the object to the database.  Validations and Callbacks are included
  by default but validation can be disabled by passing :validate => false
  to #save!  Creates a new transaction.

  .. code-block:: ruby

     def save!(*args)
       save(*args) or fail(RecordInvalidError, self) # rubocop:disable Style/AndOr
     end



.. _`Neo4j/ActiveNode/Persistence#touch`:

**#touch**
  

  .. code-block:: ruby

     def touch
       fail 'Cannot touch on a new record object' unless persisted?
       update_attribute!(:updated_at, Time.now) if respond_to?(:updated_at=)
     end



.. _`Neo4j/ActiveNode/Persistence#update`:

**#update**
  Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  If saving fails because the resource is invalid then false will be returned.

  .. code-block:: ruby

     def update(attributes)
       self.attributes = process_attributes(attributes)
       save
     end



.. _`Neo4j/ActiveNode/Persistence#update!`:

**#update!**
  Same as {#update_attributes}, but raises an exception if saving fails.

  .. code-block:: ruby

     def update!(attributes)
       self.attributes = process_attributes(attributes)
       save!
     end



.. _`Neo4j/ActiveNode/Persistence#update_attribute`:

**#update_attribute**
  Convenience method to set attribute and #save at the same time

  .. code-block:: ruby

     def update_attribute(attribute, value)
       send("#{attribute}=", value)
       self.save
     end



.. _`Neo4j/ActiveNode/Persistence#update_attribute!`:

**#update_attribute!**
  Convenience method to set attribute and #save! at the same time

  .. code-block:: ruby

     def update_attribute!(attribute, value)
       send("#{attribute}=", value)
       self.save!
     end



.. _`Neo4j/ActiveNode/Persistence#update_attributes`:

**#update_attributes**
  Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  If saving fails because the resource is invalid then false will be returned.

  .. code-block:: ruby

     def update(attributes)
       self.attributes = process_attributes(attributes)
       save
     end



.. _`Neo4j/ActiveNode/Persistence#update_attributes!`:

**#update_attributes!**
  Same as {#update_attributes}, but raises an exception if saving fails.

  .. code-block:: ruby

     def update!(attributes)
       self.attributes = process_attributes(attributes)
       save!
     end



.. _`Neo4j/ActiveNode/Persistence#update_model`:

**#update_model**
  

  .. code-block:: ruby

     def update_model
       return if !changed_attributes || changed_attributes.empty?
       _persisted_obj.update_props(props_for_update)
       changed_attributes.clear
     end





