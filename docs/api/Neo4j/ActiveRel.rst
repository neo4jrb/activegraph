ActiveRel
=========




.. toctree::
   :maxdepth: 3
   :titlesonly:


   ActiveRel/FrozenRelError

   

   

   ActiveRel/Query

   ActiveRel/Types

   ActiveRel/Property

   ActiveRel/Callbacks

   ActiveRel/Initialize

   ActiveRel/Persistence

   ActiveRel/Validations

   ActiveRel/RelatedNode




Constants
---------



  * WRAPPED_CLASSES

  * N1_N2_STRING

  * ACTIVEREL_NODE_MATCH_STRING

  * USES_CLASSNAME

  * ILLEGAL_PROPS



Files
-----



  * `lib/neo4j/active_rel.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel.rb#L4>`_

  * `lib/neo4j/active_rel/query.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/query.rb#L1>`_

  * `lib/neo4j/active_rel/types.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/types.rb#L2>`_

  * `lib/neo4j/active_rel/property.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/property.rb#L1>`_

  * `lib/neo4j/active_rel/callbacks.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/callbacks.rb#L2>`_

  * `lib/neo4j/active_rel/initialize.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/initialize.rb#L1>`_

  * `lib/neo4j/active_rel/persistence.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/persistence.rb#L1>`_

  * `lib/neo4j/active_rel/validations.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/validations.rb#L2>`_

  * `lib/neo4j/active_rel/related_node.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/related_node.rb#L1>`_





Methods
-------


.. _ActiveRel_==:

**#==**
  

  .. hidden-code-block:: ruby

     def ==(other)
       other.class == self.class && other.id == id
     end


.. _ActiveRel_[]:

**#[]**
  Returning nil when we get ActiveAttr::UnknownAttributeError from ActiveAttr

  .. hidden-code-block:: ruby

     def read_attribute(name)
       super(name)
     rescue ActiveAttr::UnknownAttributeError
       nil
     end


.. _ActiveRel__persisted_obj:

**#_persisted_obj**
  Returns the value of attribute _persisted_obj

  .. hidden-code-block:: ruby

     def _persisted_obj
       @_persisted_obj
     end


.. _ActiveRel_cache_key:

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


.. _ActiveRel_clear_association_cache:

**#clear_association_cache**
  

  .. hidden-code-block:: ruby

     def clear_association_cache; end


.. _ActiveRel_convert_properties_to:

**#convert_properties_to**
  

  .. hidden-code-block:: ruby

     def convert_properties_to(medium, properties)
       converter = medium == :ruby ? :to_ruby : :to_db
     
       properties.each_with_object({}) do |(attr, value), new_attributes|
         next new_attributes if skip_conversion?(attr, value)
         new_attributes[attr] = converted_property(primitive_type(attr.to_sym), value, converter)
       end
     end


.. _ActiveRel_default_properties:

**#default_properties**
  

  .. hidden-code-block:: ruby

     def default_properties
       @default_properties ||= Hash.new(nil)
       # keys = self.class.default_properties.keys
       # _persisted_obj.props.reject{|key| !keys.include?(key)}
     end


.. _ActiveRel_default_properties=:

**#default_properties=**
  

  .. hidden-code-block:: ruby

     def default_properties=(properties)
       keys = self.class.default_properties.keys
       @default_properties = properties.select { |key| keys.include?(key) }
     end


.. _ActiveRel_default_property:

**#default_property**
  

  .. hidden-code-block:: ruby

     def default_property(key)
       default_properties[key.to_sym]
     end


.. _ActiveRel_destroy:

**#destroy**
  :nodoc:

  .. hidden-code-block:: ruby

     def destroy #:nodoc:
       tx = Neo4j::Transaction.new
       run_callbacks(:destroy) { super }
     rescue
       @_deleted = false
       @attributes = @attributes.dup
       tx.mark_failed
       raise
     ensure
       tx.close if tx
     end


.. _ActiveRel_destroyed?:

**#destroyed?**
  Returns +true+ if the object was destroyed.

  .. hidden-code-block:: ruby

     def destroyed?
       @_deleted || (!new_record? && !exist?)
     end


.. _ActiveRel_end_node:

**#end_node**
  

  .. hidden-code-block:: ruby

     alias_method :end_node,   :to_node


.. _ActiveRel_eql?:

**#eql?**
  

  .. hidden-code-block:: ruby

     def ==(other)
       other.class == self.class && other.id == id
     end


.. _ActiveRel_exist?:

**#exist?**
  

  .. hidden-code-block:: ruby

     def exist?
       _persisted_obj && _persisted_obj.exist?
     end


.. _ActiveRel_freeze:

**#freeze**
  

  .. hidden-code-block:: ruby

     def freeze
       @attributes.freeze
       self
     end


.. _ActiveRel_frozen?:

**#frozen?**
  

  .. hidden-code-block:: ruby

     def frozen?
       @attributes.frozen?
     end


.. _ActiveRel_hash:

**#hash**
  

  .. hidden-code-block:: ruby

     def hash
       id.hash
     end


.. _ActiveRel_id:

**#id**
  

  .. hidden-code-block:: ruby

     def id
       id = neo_id
       id.is_a?(Integer) ? id : nil
     end


.. _ActiveRel_init_on_load:

**#init_on_load**
  called when loading the rel from the database

  .. hidden-code-block:: ruby

     def init_on_load(persisted_rel, from_node_id, to_node_id, type)
       @_persisted_obj = persisted_rel
       @rel_type = type
       changed_attributes && changed_attributes.clear
       @attributes = attributes.merge(persisted_rel.props.stringify_keys)
       load_nodes(from_node_id, to_node_id)
       self.default_properties = persisted_rel.props
       @attributes = convert_properties_to :ruby, @attributes
     end


.. _ActiveRel_initialize:

**#initialize**
  

  .. hidden-code-block:: ruby

     def initialize(*args)
       load_nodes
       super
     end


.. _ActiveRel_neo4j_obj:

**#neo4j_obj**
  

  .. hidden-code-block:: ruby

     def neo4j_obj
       _persisted_obj || fail('Tried to access native neo4j object on a non persisted object')
     end


.. _ActiveRel_neo_id:

**#neo_id**
  

  .. hidden-code-block:: ruby

     def neo_id
       _persisted_obj ? _persisted_obj.neo_id : nil
     end


.. _ActiveRel_new?:

**#new?**
  Returns +true+ if the record hasn't been saved to Neo4j yet.

  .. hidden-code-block:: ruby

     def new_record?
       !_persisted_obj
     end


.. _ActiveRel_new_record?:

**#new_record?**
  Returns +true+ if the record hasn't been saved to Neo4j yet.

  .. hidden-code-block:: ruby

     def new_record?
       !_persisted_obj
     end


.. _ActiveRel_persisted?:

**#persisted?**
  Returns +true+ if the record is persisted, i.e. it's not a new record and it was not destroyed

  .. hidden-code-block:: ruby

     def persisted?
       !new_record? && !destroyed?
     end


.. _ActiveRel_props:

**#props**
  

  .. hidden-code-block:: ruby

     def props
       attributes.reject { |_, v| v.nil? }.symbolize_keys
     end


.. _ActiveRel_read_attribute:

**#read_attribute**
  Returning nil when we get ActiveAttr::UnknownAttributeError from ActiveAttr

  .. hidden-code-block:: ruby

     def read_attribute(name)
       super(name)
     rescue ActiveAttr::UnknownAttributeError
       nil
     end


.. _ActiveRel_read_attribute_for_validation:

**#read_attribute_for_validation**
  Implements the ActiveModel::Validation hook method.

  .. hidden-code-block:: ruby

     def read_attribute_for_validation(key)
       respond_to?(key) ? send(key) : self[key]
     end


.. _ActiveRel_reload:

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


.. _ActiveRel_reload_from_database:

**#reload_from_database**
  

  .. hidden-code-block:: ruby

     def reload_from_database
       # TODO: - Neo4j::IdentityMap.remove_node_by_id(neo_id)
       if reloaded = self.class.load_entity(neo_id)
         send(:attributes=, reloaded.attributes)
       end
       reloaded
     end


.. _ActiveRel_save:

**#save**
  

  .. hidden-code-block:: ruby

     def save(*args)
       unless self.persisted? || (from_node.respond_to?(:neo_id) && to_node.respond_to?(:neo_id))
         fail Neo4j::ActiveRel::Persistence::RelInvalidError, 'from_node and to_node must be node objects'
       end
       super(*args)
     end


.. _ActiveRel_save!:

**#save!**
  

  .. hidden-code-block:: ruby

     def save!(*args)
       fail RelInvalidError, self unless save(*args)
     end


.. _ActiveRel_send_props:

**#send_props**
  

  .. hidden-code-block:: ruby

     def send_props(hash)
       hash.each { |key, value| self.send("#{key}=", value) }
     end


.. _ActiveRel_serializable_hash:

**#serializable_hash**
  

  .. hidden-code-block:: ruby

     def serializable_hash(*args)
       super.merge(id: id)
     end


.. _ActiveRel_serialized_properties:

**#serialized_properties**
  

  .. hidden-code-block:: ruby

     def serialized_properties
       self.class.serialized_properties
     end


.. _ActiveRel_start_node:

**#start_node**
  

  .. hidden-code-block:: ruby

     alias_method :start_node, :from_node


.. _ActiveRel_to_key:

**#to_key**
  Returns an Enumerable of all (primary) key attributes
  or nil if model.persisted? is false

  .. hidden-code-block:: ruby

     def to_key
       persisted? ? [id] : nil
     end


.. _ActiveRel_touch:

**#touch**
  :nodoc:

  .. hidden-code-block:: ruby

     def touch(*) #:nodoc:
       run_callbacks(:touch) { super }
     end


.. _ActiveRel_type:

**#type**
  

  .. hidden-code-block:: ruby

     def type
       self.class._type
     end


.. _ActiveRel_update:

**#update**
  Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  If saving fails because the resource is invalid then false will be returned.

  .. hidden-code-block:: ruby

     def update(attributes)
       self.attributes = process_attributes(attributes)
       save
     end


.. _ActiveRel_update!:

**#update!**
  Same as {#update_attributes}, but raises an exception if saving fails.

  .. hidden-code-block:: ruby

     def update!(attributes)
       self.attributes = process_attributes(attributes)
       save!
     end


.. _ActiveRel_update_attribute:

**#update_attribute**
  Convenience method to set attribute and #save at the same time

  .. hidden-code-block:: ruby

     def update_attribute(attribute, value)
       send("#{attribute}=", value)
       self.save
     end


.. _ActiveRel_update_attribute!:

**#update_attribute!**
  Convenience method to set attribute and #save! at the same time

  .. hidden-code-block:: ruby

     def update_attribute!(attribute, value)
       send("#{attribute}=", value)
       self.save!
     end


.. _ActiveRel_update_attributes:

**#update_attributes**
  Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  If saving fails because the resource is invalid then false will be returned.

  .. hidden-code-block:: ruby

     def update(attributes)
       self.attributes = process_attributes(attributes)
       save
     end


.. _ActiveRel_update_attributes!:

**#update_attributes!**
  Same as {#update_attributes}, but raises an exception if saving fails.

  .. hidden-code-block:: ruby

     def update!(attributes)
       self.attributes = process_attributes(attributes)
       save!
     end


.. _ActiveRel_valid?:

**#valid?**
  

  .. hidden-code-block:: ruby

     def valid?(context = nil)
       context     ||= (new_record? ? :create : :update)
       super(context)
       errors.empty?
     end


.. _ActiveRel_wrapper:

**#wrapper**
  Implements the Neo4j::Node#wrapper and Neo4j::Relationship#wrapper method
  so that we don't have to care if the node is wrapped or not.

  .. hidden-code-block:: ruby

     def wrapper
       self
     end





