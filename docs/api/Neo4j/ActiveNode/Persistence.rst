Persistence
===========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   Persistence/RecordInvalidError

   

   

   

   

   Persistence/ClassMethods




Constants
---------



  * USES_CLASSNAME



Files
-----



  * `lib/neo4j/active_node/persistence.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/persistence.rb#L2>`_





Methods
-------



.. _`Neo4j/ActiveNode/Persistence#_create_node`:

**#_create_node**
  

  .. hidden-code-block:: ruby

     def _create_node(*args)
       session = self.class.neo4j_session
       props = self.class.default_property_values(self)
       props.merge!(args[0]) if args[0].is_a?(Hash)
       set_classname(props)
       labels = self.class.mapped_label_names
       session.create_node(props, labels)
     end



.. _`Neo4j/ActiveNode/Persistence#cache_key`:

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



.. _`Neo4j/ActiveNode/Persistence#convert_properties_to`:

**#convert_properties_to**
  

  .. hidden-code-block:: ruby

     def convert_properties_to(medium, properties)
       converter = medium == :ruby ? :to_ruby : :to_db
       properties.each_pair do |attr, value|
         next if skip_conversion?(attr, value)
         properties[attr] = converted_property(primitive_type(attr.to_sym), value, converter)
       end
     end



.. _`Neo4j/ActiveNode/Persistence#create_model`:

**#create_model**
  Creates a model with values matching those of the instance attributes and returns its id.

  .. hidden-code-block:: ruby

     def create_model(*)
       create_magic_properties
       set_timestamps
       create_magic_properties
       properties = convert_properties_to :db, props
       node = _create_node(properties)
       init_on_load(node, node.props)
       send_props(@relationship_props) if @relationship_props
       @relationship_props = nil
       # Neo4j::IdentityMap.add(node, self)
       # write_changed_relationships
       true
     end



.. _`Neo4j/ActiveNode/Persistence#create_or_update`:

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



.. _`Neo4j/ActiveNode/Persistence#destroy`:

**#destroy**
  

  .. hidden-code-block:: ruby

     def destroy
       freeze
       _persisted_obj && _persisted_obj.del
       @_deleted = true
     end



.. _`Neo4j/ActiveNode/Persistence#destroyed?`:

**#destroyed?**
  Returns +true+ if the object was destroyed.

  .. hidden-code-block:: ruby

     def destroyed?
       @_deleted || (!new_record? && !exist?)
     end



.. _`Neo4j/ActiveNode/Persistence#exist?`:

**#exist?**
  

  .. hidden-code-block:: ruby

     def exist?
       _persisted_obj && _persisted_obj.exist?
     end



.. _`Neo4j/ActiveNode/Persistence#freeze`:

**#freeze**
  

  .. hidden-code-block:: ruby

     def freeze
       @attributes.freeze
       self
     end



.. _`Neo4j/ActiveNode/Persistence#frozen?`:

**#frozen?**
  

  .. hidden-code-block:: ruby

     def frozen?
       @attributes.frozen?
     end



.. _`Neo4j/ActiveNode/Persistence#new?`:

**#new?**
  Returns +true+ if the record hasn't been saved to Neo4j yet.

  .. hidden-code-block:: ruby

     def new_record?
       !_persisted_obj
     end



.. _`Neo4j/ActiveNode/Persistence#new_record?`:

**#new_record?**
  Returns +true+ if the record hasn't been saved to Neo4j yet.

  .. hidden-code-block:: ruby

     def new_record?
       !_persisted_obj
     end



.. _`Neo4j/ActiveNode/Persistence#persisted?`:

**#persisted?**
  Returns +true+ if the record is persisted, i.e. it's not a new record and it was not destroyed

  .. hidden-code-block:: ruby

     def persisted?
       !new_record? && !destroyed?
     end



.. _`Neo4j/ActiveNode/Persistence#props`:

**#props**
  

  .. hidden-code-block:: ruby

     def props
       attributes.reject { |_, v| v.nil? }.symbolize_keys
     end



.. _`Neo4j/ActiveNode/Persistence#reload`:

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



.. _`Neo4j/ActiveNode/Persistence#reload_from_database`:

**#reload_from_database**
  

  .. hidden-code-block:: ruby

     def reload_from_database
       # TODO: - Neo4j::IdentityMap.remove_node_by_id(neo_id)
       if reloaded = self.class.load_entity(neo_id)
         send(:attributes=, reloaded.attributes)
       end
       reloaded
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

  .. hidden-code-block:: ruby

     def save(*)
       update_magic_properties
       association_proxy_cache.clear
       create_or_update
     end



.. _`Neo4j/ActiveNode/Persistence#save!`:

**#save!**
  Persist the object to the database.  Validations and Callbacks are included
  by default but validation can be disabled by passing :validate => false
  to #save!  Creates a new transaction.

  .. hidden-code-block:: ruby

     def save!(*args)
       fail RecordInvalidError, self unless save(*args)
     end



.. _`Neo4j/ActiveNode/Persistence#update`:

**#update**
  Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  If saving fails because the resource is invalid then false will be returned.

  .. hidden-code-block:: ruby

     def update(attributes)
       self.attributes = process_attributes(attributes)
       save
     end



.. _`Neo4j/ActiveNode/Persistence#update!`:

**#update!**
  Same as {#update_attributes}, but raises an exception if saving fails.

  .. hidden-code-block:: ruby

     def update!(attributes)
       self.attributes = process_attributes(attributes)
       save!
     end



.. _`Neo4j/ActiveNode/Persistence#update_attribute`:

**#update_attribute**
  Convenience method to set attribute and #save at the same time

  .. hidden-code-block:: ruby

     def update_attribute(attribute, value)
       send("#{attribute}=", value)
       self.save
     end



.. _`Neo4j/ActiveNode/Persistence#update_attribute!`:

**#update_attribute!**
  Convenience method to set attribute and #save! at the same time

  .. hidden-code-block:: ruby

     def update_attribute!(attribute, value)
       send("#{attribute}=", value)
       self.save!
     end



.. _`Neo4j/ActiveNode/Persistence#update_attributes`:

**#update_attributes**
  Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  If saving fails because the resource is invalid then false will be returned.

  .. hidden-code-block:: ruby

     def update(attributes)
       self.attributes = process_attributes(attributes)
       save
     end



.. _`Neo4j/ActiveNode/Persistence#update_attributes!`:

**#update_attributes!**
  Same as {#update_attributes}, but raises an exception if saving fails.

  .. hidden-code-block:: ruby

     def update!(attributes)
       self.attributes = process_attributes(attributes)
       save!
     end



.. _`Neo4j/ActiveNode/Persistence#update_model`:

**#update_model**
  

  .. hidden-code-block:: ruby

     def update_model
       return if !changed_attributes || changed_attributes.empty?
     
       changed_props = attributes.select { |k, _| changed_attributes.include?(k) }
       changed_props = convert_properties_to :db, changed_props
       _persisted_obj.update_props(changed_props)
       changed_attributes.clear
     end





