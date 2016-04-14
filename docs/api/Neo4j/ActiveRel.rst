ActiveRel
=========



Makes Neo4j Relationships more or less act like ActiveRecord objects.
See documentation at https://github.com/neo4jrb/neo4j/wiki/Neo4j%3A%3AActiveRel


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   ActiveRel/FrozenRelError

   

   

   

   

   

   ActiveRel/ClassMethods

   ActiveRel/Types

   ActiveRel/Query

   ActiveRel/Property

   ActiveRel/Callbacks

   ActiveRel/Initialize

   ActiveRel/Persistence

   ActiveRel/Validations

   ActiveRel/RelatedNode




Constants
---------



  * MARSHAL_INSTANCE_VARIABLES

  * WRAPPED_CLASSES

  * DATE_KEY_REGEX

  * DEPRECATED_OBJECT_METHODS



Files
-----



  * `lib/neo4j/active_rel.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel.rb#L4>`_

  * `lib/neo4j/active_rel/types.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/types.rb#L2>`_

  * `lib/neo4j/active_rel/query.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/query.rb#L1>`_

  * `lib/neo4j/active_rel/property.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/property.rb#L3>`_

  * `lib/neo4j/active_rel/callbacks.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/callbacks.rb#L2>`_

  * `lib/neo4j/active_rel/initialize.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/initialize.rb#L1>`_

  * `lib/neo4j/active_rel/persistence.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/persistence.rb#L1>`_

  * `lib/neo4j/active_rel/validations.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/validations.rb#L2>`_

  * `lib/neo4j/active_rel/related_node.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/related_node.rb#L1>`_





Methods
-------



.. _`Neo4j/ActiveRel#==`:

**#==**
  Performs equality checking on the result of attributes and its type.

  .. code-block:: ruby

     def ==(other)
       return false unless other.instance_of? self.class
       attributes == other.attributes
     end



.. _`Neo4j/ActiveRel#[]`:

**#[]**
  

  .. code-block:: ruby

     def read_attribute(name)
       respond_to?(name) ? send(name) : nil
     end



.. _`Neo4j/ActiveRel#[]=`:

**#[]=**
  Write a single attribute to the model's attribute hash.

  .. code-block:: ruby

     def write_attribute(name, value)
       if respond_to? "#{name}="
         send "#{name}=", value
       else
         fail Neo4j::UnknownAttributeError, "unknown attribute: #{name}"
       end
     end



.. _`Neo4j/ActiveRel#_persisted_obj`:

**#_persisted_obj**
  Returns the value of attribute _persisted_obj

  .. code-block:: ruby

     def _persisted_obj
       @_persisted_obj
     end



.. _`Neo4j/ActiveRel#apply_default_values`:

**#apply_default_values**
  

  .. code-block:: ruby

     def apply_default_values
       return if self.class.declared_property_defaults.empty?
       self.class.declared_property_defaults.each_pair do |key, value|
         self.send("#{key}=", value) if self.send(key).nil?
       end
     end



.. _`Neo4j/ActiveRel#assign_attributes`:

**#assign_attributes**
  Mass update a model's attributes

  .. code-block:: ruby

     def assign_attributes(new_attributes = nil)
       return unless new_attributes.present?
       new_attributes.each do |name, value|
         writer = :"#{name}="
         send(writer, value) if respond_to?(writer)
       end
     end



.. _`Neo4j/ActiveRel#attribute_before_type_cast`:

**#attribute_before_type_cast**
  Read the raw attribute value

  .. code-block:: ruby

     def attribute_before_type_cast(name)
       @attributes ||= {}
       @attributes[name.to_s]
     end



.. _`Neo4j/ActiveRel#attributes`:

**#attributes**
  Returns a Hash of all attributes

  .. code-block:: ruby

     def attributes
       attributes_map { |name| send name }
     end



.. _`Neo4j/ActiveRel#attributes=`:

**#attributes=**
  Mass update a model's attributes

  .. code-block:: ruby

     def attributes=(new_attributes)
       assign_attributes(new_attributes)
     end



.. _`Neo4j/ActiveRel#cache_key`:

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



.. _`Neo4j/ActiveRel#concurrent_increment!`:

**#concurrent_increment!**
  Increments concurrently a numeric attribute by a centain amount

  .. code-block:: ruby

     def concurrent_increment!(attribute, by = 1)
       query_rel = Neo4j::Session.query.match('()-[n]-()').where(n: {neo_id: neo_id})
       increment_by_query! query_rel, attribute, by
     end



.. _`Neo4j/ActiveRel#conditional_callback`:

**#conditional_callback**
  Allows you to perform a callback if a condition is not satisfied.

  .. code-block:: ruby

     def conditional_callback(kind, guard)
       return yield if guard
       run_callbacks(kind) { yield }
     end



.. _`Neo4j/ActiveRel#create_method`:

**#create_method**
  

  .. code-block:: ruby

     def create_method
       self.class.create_method
     end



.. _`Neo4j/ActiveRel#creates_unique_option`:

**#creates_unique_option**
  

  .. code-block:: ruby

     def creates_unique_option
       self.class.creates_unique_option
     end



.. _`Neo4j/ActiveRel#cypher_identifier`:

**#cypher_identifier**
  

  .. code-block:: ruby

     def cypher_identifier
       @cypher_identifier || :rel
     end



.. _`Neo4j/ActiveRel#declared_properties`:

**#declared_properties**
  

  .. code-block:: ruby

     def declared_properties
       self.class.declared_properties
     end



.. _`Neo4j/ActiveRel#destroy`:

**#destroy**
  :nodoc:

  .. code-block:: ruby

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



.. _`Neo4j/ActiveRel#destroyed?`:

**#destroyed?**
  Returns +true+ if the object was destroyed.

  .. code-block:: ruby

     def destroyed?
       @_deleted
     end



.. _`Neo4j/ActiveRel#end_node`:

**#end_node**
  

  .. code-block:: ruby

     alias_method :end_node,   :to_node



.. _`Neo4j/ActiveRel#eql?`:

**#eql?**
  

  .. code-block:: ruby

     def ==(other)
       other.class == self.class && other.id == id
     end



.. _`Neo4j/ActiveRel#exist?`:

**#exist?**
  

  .. code-block:: ruby

     def exist?
       _persisted_obj && _persisted_obj.exist?
     end



.. _`Neo4j/ActiveRel#freeze`:

**#freeze**
  

  .. code-block:: ruby

     def freeze
       @attributes.freeze
       self
     end



.. _`Neo4j/ActiveRel#from_node_identifier`:

**#from_node_identifier**
  

  .. code-block:: ruby

     def from_node_identifier
       @from_node_identifier || :from_node
     end



.. _`Neo4j/ActiveRel#from_node_identifier=`:

**#from_node_identifier=**
  

  .. code-block:: ruby

     def from_node_identifier=(id)
       @from_node_identifier = id.to_sym
     end



.. _`Neo4j/ActiveRel#from_node_neo_id`:

**#from_node_neo_id**
  

  .. code-block:: ruby

     alias_method :from_node_neo_id, :start_node_neo_id



.. _`Neo4j/ActiveRel#frozen?`:

**#frozen?**
  

  .. code-block:: ruby

     def frozen?
       @attributes.frozen?
     end



.. _`Neo4j/ActiveRel#hash`:

**#hash**
  

  .. code-block:: ruby

     def hash
       id.hash
     end



.. _`Neo4j/ActiveRel#id`:

**#id**
  

  .. code-block:: ruby

     def id
       id = neo_id
       id.is_a?(Integer) ? id : nil
     end



.. _`Neo4j/ActiveRel#increment`:

**#increment**
  Increments a numeric attribute by a centain amount

  .. code-block:: ruby

     def increment(attribute, by = 1)
       self[attribute] ||= 0
       self[attribute] += by
       self
     end



.. _`Neo4j/ActiveRel#increment!`:

**#increment!**
  Convenience method to increment numeric attribute and #save at the same time

  .. code-block:: ruby

     def increment!(attribute, by = 1)
       increment(attribute, by).update_attribute(attribute, self[attribute])
     end



.. _`Neo4j/ActiveRel#init_on_load`:

**#init_on_load**
  called when loading the rel from the database

  .. code-block:: ruby

     def init_on_load(persisted_rel, from_node_id, to_node_id, type)
       @rel_type = type
       @_persisted_obj = persisted_rel
       changed_attributes && changed_attributes.clear
       @attributes = convert_and_assign_attributes(persisted_rel.props)
       load_nodes(from_node_id, to_node_id)
     end



.. _`Neo4j/ActiveRel#init_on_reload`:

**#init_on_reload**
  

  .. code-block:: ruby

     def init_on_reload(unwrapped_reloaded)
       @attributes = nil
       init_on_load(unwrapped_reloaded,
                    unwrapped_reloaded._start_node_id,
                    unwrapped_reloaded._end_node_id,
                    unwrapped_reloaded.rel_type)
       self
     end



.. _`Neo4j/ActiveRel#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(from_node = nil, to_node = nil, args = nil)
       load_nodes(node_or_nil(from_node), node_or_nil(to_node))
       resolved_args = hash_or_nil(from_node, args)
       symbol_args = resolved_args.is_a?(Hash) ? resolved_args.symbolize_keys : resolved_args
       super(symbol_args)
     end



.. _`Neo4j/ActiveRel#inject_defaults!`:

**#inject_defaults!**
  

  .. code-block:: ruby

     def inject_defaults!(starting_props)
       return starting_props if self.class.declared_properties.declared_property_defaults.empty?
       self.class.declared_properties.inject_defaults!(self, starting_props || {})
     end



.. _`Neo4j/ActiveRel#inspect`:

**#inspect**
  

  .. code-block:: ruby

     def inspect
       attribute_descriptions = inspect_attributes.map do |key, value|
         "#{Neo4j::ANSI::CYAN}#{key}: #{Neo4j::ANSI::CLEAR}#{value.inspect}"
       end.join(', ')
     
       separator = ' ' unless attribute_descriptions.empty?
       "#<#{Neo4j::ANSI::YELLOW}#{self.class.name}#{Neo4j::ANSI::CLEAR}#{separator}#{attribute_descriptions}>"
     end



.. _`Neo4j/ActiveRel#marshal_dump`:

**#marshal_dump**
  

  .. code-block:: ruby

     def marshal_dump
       marshal_instance_variables.map(&method(:instance_variable_get))
     end



.. _`Neo4j/ActiveRel#marshal_load`:

**#marshal_load**
  

  .. code-block:: ruby

     def marshal_load(array)
       marshal_instance_variables.zip(array).each do |var, value|
         instance_variable_set(var, value)
       end
     end



.. _`Neo4j/ActiveRel#neo4j_obj`:

**#neo4j_obj**
  

  .. code-block:: ruby

     def neo4j_obj
       _persisted_obj || fail('Tried to access native neo4j object on a non persisted object')
     end



.. _`Neo4j/ActiveRel#neo_id`:

**#neo_id**
  

  .. code-block:: ruby

     def neo_id
       _persisted_obj ? _persisted_obj.neo_id : nil
     end



.. _`Neo4j/ActiveRel#new?`:

**#new?**
  Returns +true+ if the record hasn't been saved to Neo4j yet.

  .. code-block:: ruby

     def new_record?
       !_persisted_obj
     end



.. _`Neo4j/ActiveRel#new_record?`:

**#new_record?**
  Returns +true+ if the record hasn't been saved to Neo4j yet.

  .. code-block:: ruby

     def new_record?
       !_persisted_obj
     end



.. _`Neo4j/ActiveRel#node_cypher_representation`:

**#node_cypher_representation**
  

  .. code-block:: ruby

     def node_cypher_representation(node)
       node_class = node.class
       id_name = node_class.id_property_name
       labels = ':' + node_class.mapped_label_names.join(':')
     
       "(#{labels} {#{id_name}: #{node.id.inspect}})"
     end



.. _`Neo4j/ActiveRel#persisted?`:

**#persisted?**
  Returns +true+ if the record is persisted, i.e. it's not a new record and it was not destroyed

  .. code-block:: ruby

     def persisted?
       !new_record? && !destroyed?
     end



.. _`Neo4j/ActiveRel#props`:

**#props**
  

  .. code-block:: ruby

     def props
       attributes.reject { |_, v| v.nil? }.symbolize_keys
     end



.. _`Neo4j/ActiveRel#props_for_create`:

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



.. _`Neo4j/ActiveRel#props_for_persistence`:

**#props_for_persistence**
  

  .. code-block:: ruby

     def props_for_persistence
       _persisted_obj ? props_for_update : props_for_create
     end



.. _`Neo4j/ActiveRel#props_for_update`:

**#props_for_update**
  

  .. code-block:: ruby

     def props_for_update
       update_magic_properties
       changed_props = attributes.select { |k, _| changed_attributes.include?(k) }
       changed_props.symbolize_keys!
       inject_defaults!(changed_props)
       props_for_db(changed_props)
     end



.. _`Neo4j/ActiveRel#read_attribute`:

**#read_attribute**
  

  .. code-block:: ruby

     def read_attribute(name)
       respond_to?(name) ? send(name) : nil
     end



.. _`Neo4j/ActiveRel#read_attribute_for_validation`:

**#read_attribute_for_validation**
  Implements the ActiveModel::Validation hook method.

  .. code-block:: ruby

     def read_attribute_for_validation(key)
       respond_to?(key) ? send(key) : self[key]
     end



.. _`Neo4j/ActiveRel#rel_type`:

**#rel_type**
  

  .. code-block:: ruby

     def type
       self.class.type
     end



.. _`Neo4j/ActiveRel#reload`:

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



.. _`Neo4j/ActiveRel#reload_from_database`:

**#reload_from_database**
  

  .. code-block:: ruby

     def reload_from_database
       reloaded = self.class.load_entity(neo_id)
       reloaded ? init_on_reload(reloaded._persisted_obj) : nil
     end



.. _`Neo4j/ActiveRel#reload_properties!`:

**#reload_properties!**
  

  .. code-block:: ruby

     def reload_properties!(properties)
       @attributes = nil
       convert_and_assign_attributes(properties)
     end



.. _`Neo4j/ActiveRel#save`:

**#save**
  

  .. code-block:: ruby

     def save(*args)
       unless _persisted_obj || (from_node.respond_to?(:neo_id) && to_node.respond_to?(:neo_id))
         fail Neo4j::ActiveRel::Persistence::RelInvalidError, 'from_node and to_node must be node objects'
       end
       super(*args)
     end



.. _`Neo4j/ActiveRel#save!`:

**#save!**
  

  .. code-block:: ruby

     def save!(*args)
       save(*args) or fail(RelInvalidError, inspect) # rubocop:disable Style/AndOr
     end



.. _`Neo4j/ActiveRel#send_props`:

**#send_props**
  

  .. code-block:: ruby

     def send_props(hash)
       return hash if hash.blank?
       hash.each { |key, value| send("#{key}=", value) }
     end



.. _`Neo4j/ActiveRel#serializable_hash`:

**#serializable_hash**
  

  .. code-block:: ruby

     def serializable_hash(*args)
       super.merge(id: id)
     end



.. _`Neo4j/ActiveRel#serialized_properties`:

**#serialized_properties**
  

  .. code-block:: ruby

     def serialized_properties
       self.class.serialized_properties
     end



.. _`Neo4j/ActiveRel#start_node`:

**#start_node**
  

  .. code-block:: ruby

     alias_method :start_node, :from_node



.. _`Neo4j/ActiveRel#to_key`:

**#to_key**
  Returns an Enumerable of all (primary) key attributes
  or nil if model.persisted? is false

  .. code-block:: ruby

     def to_key
       _persisted_obj ? [id] : nil
     end



.. _`Neo4j/ActiveRel#to_node_identifier`:

**#to_node_identifier**
  

  .. code-block:: ruby

     def to_node_identifier
       @to_node_identifier || :to_node
     end



.. _`Neo4j/ActiveRel#to_node_identifier=`:

**#to_node_identifier=**
  

  .. code-block:: ruby

     def to_node_identifier=(id)
       @to_node_identifier = id.to_sym
     end



.. _`Neo4j/ActiveRel#to_node_neo_id`:

**#to_node_neo_id**
  

  .. code-block:: ruby

     alias_method :to_node_neo_id,   :end_node_neo_id



.. _`Neo4j/ActiveRel#touch`:

**#touch**
  :nodoc:

  .. code-block:: ruby

     def touch #:nodoc:
       run_callbacks(:touch) { super }
     end



.. _`Neo4j/ActiveRel#type`:

**#type**
  

  .. code-block:: ruby

     def type
       self.class.type
     end



.. _`Neo4j/ActiveRel#update`:

**#update**
  Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  If saving fails because the resource is invalid then false will be returned.

  .. code-block:: ruby

     def update(attributes)
       self.attributes = process_attributes(attributes)
       save
     end



.. _`Neo4j/ActiveRel#update!`:

**#update!**
  Same as {#update_attributes}, but raises an exception if saving fails.

  .. code-block:: ruby

     def update!(attributes)
       self.attributes = process_attributes(attributes)
       save!
     end



.. _`Neo4j/ActiveRel#update_attribute`:

**#update_attribute**
  Convenience method to set attribute and #save at the same time

  .. code-block:: ruby

     def update_attribute(attribute, value)
       send("#{attribute}=", value)
       self.save
     end



.. _`Neo4j/ActiveRel#update_attribute!`:

**#update_attribute!**
  Convenience method to set attribute and #save! at the same time

  .. code-block:: ruby

     def update_attribute!(attribute, value)
       send("#{attribute}=", value)
       self.save!
     end



.. _`Neo4j/ActiveRel#update_attributes`:

**#update_attributes**
  Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  If saving fails because the resource is invalid then false will be returned.

  .. code-block:: ruby

     def update(attributes)
       self.attributes = process_attributes(attributes)
       save
     end



.. _`Neo4j/ActiveRel#update_attributes!`:

**#update_attributes!**
  Same as {#update_attributes}, but raises an exception if saving fails.

  .. code-block:: ruby

     def update!(attributes)
       self.attributes = process_attributes(attributes)
       save!
     end



.. _`Neo4j/ActiveRel#valid?`:

**#valid?**
  

  .. code-block:: ruby

     def valid?(context = nil)
       context ||= (new_record? ? :create : :update)
       super(context)
       errors.empty?
     end



.. _`Neo4j/ActiveRel#wrapper`:

**#wrapper**
  Implements the Neo4j::Node#wrapper and Neo4j::Relationship#wrapper method
  so that we don't have to care if the node is wrapped or not.

  .. code-block:: ruby

     def wrapper
       self
     end



.. _`Neo4j/ActiveRel#write_attribute`:

**#write_attribute**
  Write a single attribute to the model's attribute hash.

  .. code-block:: ruby

     def write_attribute(name, value)
       if respond_to? "#{name}="
         send "#{name}=", value
       else
         fail Neo4j::UnknownAttributeError, "unknown attribute: #{name}"
       end
     end





