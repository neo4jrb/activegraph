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



  * lib/neo4j/active_node/persistence.rb:2





Methods
-------


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


**#convert_properties_to**
  

  .. hidden-code-block:: ruby

     def convert_properties_to(medium, properties)
       converter = medium == :ruby ? :to_ruby : :to_db
     
       properties.each_with_object({}) do |(attr, value), new_attributes|
         next new_attributes if skip_conversion?(attr, value)
         new_attributes[attr] = converted_property(primitive_type(attr.to_sym), value, converter)
       end
     end


**#converted_property**
  

  .. hidden-code-block:: ruby

     def converted_property(type, value, converter)
       TypeConverters.converters[type].nil? ? value : TypeConverters.to_other(converter, value, type)
     end


**#create_magic_properties**
  

  .. hidden-code-block:: ruby

     def create_magic_properties
     end


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


**#destroy**
  

  .. hidden-code-block:: ruby

     def destroy
       freeze
       _persisted_obj && _persisted_obj.del
       @_deleted = true
     end


**#destroyed?**
  Returns +true+ if the object was destroyed.

  .. hidden-code-block:: ruby

     def destroyed?
       @_deleted || (!new_record? && !exist?)
     end


**#exist?**
  

  .. hidden-code-block:: ruby

     def exist?
       _persisted_obj && _persisted_obj.exist?
     end


**#freeze**
  

  .. hidden-code-block:: ruby

     def freeze
       @attributes.freeze
       self
     end


**#frozen?**
  

  .. hidden-code-block:: ruby

     def frozen?
       @attributes.frozen?
     end


**#model_cache_key**
  

  .. hidden-code-block:: ruby

     def model_cache_key
       self.class.model_name.cache_key
     end


**#new?**
  Returns +true+ if the record hasn't been saved to Neo4j yet.

  .. hidden-code-block:: ruby

     def new_record?
       !_persisted_obj
     end


**#new_record?**
  Returns +true+ if the record hasn't been saved to Neo4j yet.

  .. hidden-code-block:: ruby

     def new_record?
       !_persisted_obj
     end


**#persisted?**
  Returns +true+ if the record is persisted, i.e. it's not a new record and it was not destroyed

  .. hidden-code-block:: ruby

     def persisted?
       !new_record? && !destroyed?
     end


**#primitive_type**
  If the attribute is to be typecast using a custom converter, which converter should it use? If no, returns the type to find a native serializer.

  .. hidden-code-block:: ruby

     def primitive_type(attr)
       case
       when serialized_properties.key?(attr)
         serialized_properties[attr]
       when magic_typecast_properties.key?(attr)
         self.class.magic_typecast_properties[attr]
       else
         self.class._attribute_type(attr)
       end
     end


**#props**
  

  .. hidden-code-block:: ruby

     def props
       attributes.reject { |_, v| v.nil? }.symbolize_keys
     end


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


**#reload_from_database**
  

  .. hidden-code-block:: ruby

     def reload_from_database
       # TODO: - Neo4j::IdentityMap.remove_node_by_id(neo_id)
       if reloaded = self.class.load_entity(neo_id)
         send(:attributes=, reloaded.attributes)
       end
       reloaded
     end


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
       clear_association_cache
       create_or_update
     end


**#save!**
  Persist the object to the database.  Validations and Callbacks are included
  by default but validation can be disabled by passing :validate => false
  to #save!  Creates a new transaction.

  .. hidden-code-block:: ruby

     def save!(*args)
       fail RecordInvalidError, self unless save(*args)
     end


**#set_classname**
  Inserts the _classname property into an object's properties during object creation.

  .. hidden-code-block:: ruby

     def set_classname(props, check_version = true)
       props[:_classname] = self.class.name if self.class.cached_class?(check_version)
     end


**#set_timestamps**
  

  .. hidden-code-block:: ruby

     def set_timestamps
       now = DateTime.now
       self.created_at ||= now if respond_to?(:created_at=)
       self.updated_at ||= now if respond_to?(:updated_at=)
     end


**#skip_conversion?**
  Returns true if the property isn't defined in the model or it's both nil and unchanged.

  .. hidden-code-block:: ruby

     def skip_conversion?(attr, value)
       !self.class.attributes[attr] || (value.nil? && !changed_attributes.key?(attr))
     end


**#update**
  Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  If saving fails because the resource is invalid then false will be returned.

  .. hidden-code-block:: ruby

     def update(attributes)
       self.attributes = process_attributes(attributes)
       save
     end


**#update!**
  Same as {#update_attributes}, but raises an exception if saving fails.

  .. hidden-code-block:: ruby

     def update!(attributes)
       self.attributes = process_attributes(attributes)
       save!
     end


**#update_attribute**
  Convenience method to set attribute and #save at the same time

  .. hidden-code-block:: ruby

     def update_attribute(attribute, value)
       send("#{attribute}=", value)
       self.save
     end


**#update_attribute!**
  Convenience method to set attribute and #save! at the same time

  .. hidden-code-block:: ruby

     def update_attribute!(attribute, value)
       send("#{attribute}=", value)
       self.save!
     end


**#update_attributes**
  Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  If saving fails because the resource is invalid then false will be returned.

  .. hidden-code-block:: ruby

     def update(attributes)
       self.attributes = process_attributes(attributes)
       save
     end


**#update_attributes!**
  Same as {#update_attributes}, but raises an exception if saving fails.

  .. hidden-code-block:: ruby

     def update!(attributes)
       self.attributes = process_attributes(attributes)
       save!
     end


**#update_magic_properties**
  

  .. hidden-code-block:: ruby

     def update_magic_properties
       self.updated_at = DateTime.now if respond_to?(:updated_at=) && changed? && !updated_at_changed?
     end


**#update_model**
  

  .. hidden-code-block:: ruby

     def update_model
       return if !changed_attributes || changed_attributes.empty?
     
       changed_props = attributes.select { |k, _| changed_attributes.include?(k) }
       changed_props = convert_properties_to :db, changed_props
       _persisted_obj.update_props(changed_props)
       changed_attributes.clear
     end





