ActiveNode
==========



Makes Neo4j nodes and relationships behave like ActiveRecord objects.
By including this module in your class it will create a mapping for the node to your ruby class
by using a Neo4j Label with the same name as the class. When the node is loaded from the database it
will check if there is a ruby class for the labels it has.
If there Ruby class with the same name as the label then the Neo4j node will be wrapped
in a new object of that class.

= ClassMethods
* {Neo4j::ActiveNode::Labels::ClassMethods} defines methods like: <tt>index</tt> and <tt>find</tt>
* {Neo4j::ActiveNode::Persistence::ClassMethods} defines methods like: <tt>create</tt> and <tt>create!</tt>
* {Neo4j::ActiveNode::Property::ClassMethods} defines methods like: <tt>property</tt>.


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   ActiveNode/ClassMethods

   ActiveNode/Enum

   ActiveNode/Rels

   ActiveNode/Query

   ActiveNode/HasN

   ActiveNode/Scope

   ActiveNode/Labels

   ActiveNode/Property

   ActiveNode/Dependent

   ActiveNode/Callbacks

   ActiveNode/Initialize

   ActiveNode/Reflection

   ActiveNode/Validations

   ActiveNode/OrmAdapter

   ActiveNode/Persistence

   ActiveNode/IdProperty

   ActiveNode/Unpersisted

   ActiveNode/QueryMethods




Constants
---------



  * MARSHAL_INSTANCE_VARIABLES

  * WRAPPED_CLASSES

  * MODELS_FOR_LABELS_CACHE

  * MODELS_TO_RELOAD

  * DATE_KEY_REGEX

  * DEPRECATED_OBJECT_METHODS



Files
-----



  * `lib/neo4j/active_node.rb:23 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node.rb#L23>`_

  * `lib/neo4j/active_node/enum.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/enum.rb#L1>`_

  * `lib/neo4j/active_node/rels.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/rels.rb#L1>`_

  * `lib/neo4j/active_node/query.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query.rb#L2>`_

  * `lib/neo4j/active_node/has_n.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/has_n.rb#L1>`_

  * `lib/neo4j/active_node/scope.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/scope.rb#L3>`_

  * `lib/neo4j/active_node/labels.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/labels.rb#L2>`_

  * `lib/neo4j/active_node/property.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/property.rb#L1>`_

  * `lib/neo4j/active_node/dependent.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/dependent.rb#L2>`_

  * `lib/neo4j/active_node/callbacks.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/callbacks.rb#L2>`_

  * `lib/neo4j/active_node/reflection.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/reflection.rb#L1>`_

  * `lib/neo4j/active_node/validations.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/validations.rb#L2>`_

  * `lib/neo4j/active_node/orm_adapter.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/orm_adapter.rb#L4>`_

  * `lib/neo4j/active_node/persistence.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/persistence.rb#L1>`_

  * `lib/neo4j/active_node/id_property.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/id_property.rb#L1>`_

  * `lib/neo4j/active_node/unpersisted.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/unpersisted.rb#L2>`_

  * `lib/neo4j/active_node/query_methods.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query_methods.rb#L2>`_

  * `lib/neo4j/active_node/has_n/association.rb:5 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/has_n/association.rb#L5>`_

  * `lib/neo4j/active_node/query/query_proxy.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy.rb#L2>`_

  * `lib/neo4j/active_node/query/query_proxy_link.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_link.rb#L2>`_

  * `lib/neo4j/active_node/query/query_proxy_methods.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_methods.rb#L2>`_

  * `lib/neo4j/active_node/query/query_proxy_enumerable.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_enumerable.rb#L2>`_

  * `lib/neo4j/active_node/dependent/association_methods.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/dependent/association_methods.rb#L2>`_

  * `lib/neo4j/active_node/dependent/query_proxy_methods.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/dependent/query_proxy_methods.rb#L2>`_

  * `lib/neo4j/active_node/query/query_proxy_eager_loading.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_eager_loading.rb#L2>`_

  * `lib/neo4j/active_node/has_n/association_cypher_methods.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/has_n/association_cypher_methods.rb#L2>`_

  * `lib/neo4j/active_node/query/query_proxy_find_in_batches.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_find_in_batches.rb#L2>`_

  * `lib/neo4j/active_node/query/query_proxy_methods_of_mass_updating.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_methods_of_mass_updating.rb#L2>`_





Methods
-------



.. _`Neo4j/ActiveNode#==`:

**#==**
  Performs equality checking on the result of attributes and its type.

  .. code-block:: ruby

     def ==(other)
       return false unless other.instance_of? self.class
       attributes == other.attributes
     end



.. _`Neo4j/ActiveNode#[]`:

**#[]**
  

  .. code-block:: ruby

     def read_attribute(name)
       respond_to?(name) ? send(name) : nil
     end



.. _`Neo4j/ActiveNode#[]=`:

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



.. _`Neo4j/ActiveNode#_create_node`:

**#_create_node**
  TODO: This does not seem like it should be the responsibility of the node.
  Creates an unwrapped node in the database.

  .. code-block:: ruby

     def _create_node(node_props, labels = labels_for_create)
       self.class.neo4j_session.create_node(node_props, labels)
     end



.. _`Neo4j/ActiveNode#_persisted_obj`:

**#_persisted_obj**
  Returns the value of attribute _persisted_obj

  .. code-block:: ruby

     def _persisted_obj
       @_persisted_obj
     end



.. _`Neo4j/ActiveNode#_rels_delegator`:

**#_rels_delegator**
  

  .. code-block:: ruby

     def _rels_delegator
       fail "Can't access relationship on a non persisted node" unless _persisted_obj
       _persisted_obj
     end



.. _`Neo4j/ActiveNode#add_label`:

**#add_label**
  adds one or more labels

  .. code-block:: ruby

     def add_label(*label)
       @_persisted_obj.add_label(*label)
     end



.. _`Neo4j/ActiveNode#apply_default_values`:

**#apply_default_values**
  

  .. code-block:: ruby

     def apply_default_values
       return if self.class.declared_property_defaults.empty?
       self.class.declared_property_defaults.each_pair do |key, value|
         self.send("#{key}=", value) if self.send(key).nil?
       end
     end



.. _`Neo4j/ActiveNode#as`:

**#as**
  Starts a new QueryProxy with the starting identifier set to the given argument and QueryProxy source_object set to the node instance.
  This method does not exist within QueryProxy and can only be used to start a new chain.

  .. code-block:: ruby

     def as(node_var)
       self.class.query_proxy(node: node_var, source_object: self).match_to(self)
     end



.. _`Neo4j/ActiveNode#assign_attributes`:

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



.. _`Neo4j/ActiveNode#association_proxy`:

**#association_proxy**
  

  .. code-block:: ruby

     def association_proxy(name, options = {})
       name = name.to_sym
       hash = association_proxy_hash(name, options)
       association_proxy_cache_fetch(hash) do
         if result_cache = self.instance_variable_get('@source_proxy_result_cache')
           result_by_previous_id = previous_proxy_results_by_previous_id(result_cache, name)
     
           result_cache.inject(nil) do |proxy_to_return, object|
             proxy = fresh_association_proxy(name, options.merge(start_object: object), result_by_previous_id[object.neo_id])
     
             object.association_proxy_cache[hash] = proxy
     
             (self == object ? proxy : proxy_to_return)
           end
         else
           fresh_association_proxy(name, options)
         end
       end
     end



.. _`Neo4j/ActiveNode#association_proxy_cache`:

**#association_proxy_cache**
  Returns the current AssociationProxy cache for the association cache. It is in the format
  { :association_name => AssociationProxy}
  This is so that we
  * don't need to re-build the QueryProxy objects
  * also because the QueryProxy object caches it's results
  * so we don't need to query again
  * so that we can cache results from association calls or eager loading

  .. code-block:: ruby

     def association_proxy_cache
       @association_proxy_cache ||= {}
     end



.. _`Neo4j/ActiveNode#association_proxy_cache_fetch`:

**#association_proxy_cache_fetch**
  

  .. code-block:: ruby

     def association_proxy_cache_fetch(key)
       association_proxy_cache.fetch(key) do
         value = yield
         association_proxy_cache[key] = value
       end
     end



.. _`Neo4j/ActiveNode#association_proxy_hash`:

**#association_proxy_hash**
  

  .. code-block:: ruby

     def association_proxy_hash(name, options = {})
       [name.to_sym, options.values_at(:node, :rel, :labels, :rel_length)].hash
     end



.. _`Neo4j/ActiveNode#association_query_proxy`:

**#association_query_proxy**
  

  .. code-block:: ruby

     def association_query_proxy(name, options = {})
       self.class.send(:association_query_proxy, name, {start_object: self}.merge!(options))
     end



.. _`Neo4j/ActiveNode#attribute_before_type_cast`:

**#attribute_before_type_cast**
  Read the raw attribute value

  .. code-block:: ruby

     def attribute_before_type_cast(name)
       @attributes ||= {}
       @attributes[name.to_s]
     end



.. _`Neo4j/ActiveNode#attributes`:

**#attributes**
  Returns a Hash of all attributes

  .. code-block:: ruby

     def attributes
       attributes_map { |name| send name }
     end



.. _`Neo4j/ActiveNode#attributes=`:

**#attributes=**
  Mass update a model's attributes

  .. code-block:: ruby

     def attributes=(new_attributes)
       assign_attributes(new_attributes)
     end



.. _`Neo4j/ActiveNode#cache_key`:

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



.. _`Neo4j/ActiveNode#called_by`:

**#called_by**
  Returns the value of attribute called_by

  .. code-block:: ruby

     def called_by
       @called_by
     end



.. _`Neo4j/ActiveNode#called_by=`:

**#called_by=**
  Sets the attribute called_by

  .. code-block:: ruby

     def called_by=(value)
       @called_by = value
     end



.. _`Neo4j/ActiveNode#clear_deferred_nodes_for_association`:

**#clear_deferred_nodes_for_association**
  

  .. code-block:: ruby

     def clear_deferred_nodes_for_association(association_name)
       deferred_nodes_for_association(association_name.to_sym).clear
     end



.. _`Neo4j/ActiveNode#concurrent_increment!`:

**#concurrent_increment!**
  Increments concurrently a numeric attribute by a centain amount

  .. code-block:: ruby

     def concurrent_increment!(attribute, by = 1)
       query_node = Neo4j::Session.query.match_nodes(n: neo_id)
       increment_by_query! query_node, attribute, by
     end



.. _`Neo4j/ActiveNode#conditional_callback`:

**#conditional_callback**
  Allows you to perform a callback if a condition is not satisfied.

  .. code-block:: ruby

     def conditional_callback(kind, guard)
       return yield if guard
       run_callbacks(kind) { yield }
     end



.. _`Neo4j/ActiveNode#declared_properties`:

**#declared_properties**
  

  .. code-block:: ruby

     def declared_properties
       self.class.declared_properties
     end



.. _`Neo4j/ActiveNode#default_properties`:

**#default_properties**
  

  .. code-block:: ruby

     def default_properties
       @default_properties ||= Hash.new(nil)
     end



.. _`Neo4j/ActiveNode#default_properties=`:

**#default_properties=**
  

  .. code-block:: ruby

     def default_properties=(properties)
       @default_property_value = properties[default_property_key]
     end



.. _`Neo4j/ActiveNode#default_property`:

**#default_property**
  

  .. code-block:: ruby

     def default_property(key)
       return nil unless key == default_property_key
       default_property_value
     end



.. _`Neo4j/ActiveNode#default_property_key`:

**#default_property_key**
  

  .. code-block:: ruby

     def default_property_key
       self.class.default_property_key
     end



.. _`Neo4j/ActiveNode#default_property_value`:

**#default_property_value**
  Returns the value of attribute default_property_value

  .. code-block:: ruby

     def default_property_value
       @default_property_value
     end



.. _`Neo4j/ActiveNode#defer_create`:

**#defer_create**
  

  .. code-block:: ruby

     def defer_create(association_name, object, options = {})
       clear_deferred_nodes_for_association(association_name) if options[:clear]
     
       deferred_nodes_for_association(association_name) << object
     end



.. _`Neo4j/ActiveNode#deferred_create_cache`:

**#deferred_create_cache**
  The values in this Hash are returned and used outside by reference
  so any modifications to the Array should be in-place

  .. code-block:: ruby

     def deferred_create_cache
       @deferred_create_cache ||= {}
     end



.. _`Neo4j/ActiveNode#deferred_nodes_for_association`:

**#deferred_nodes_for_association**
  

  .. code-block:: ruby

     def deferred_nodes_for_association(association_name)
       deferred_create_cache[association_name.to_sym] ||= []
     end



.. _`Neo4j/ActiveNode#dependent_children`:

**#dependent_children**
  

  .. code-block:: ruby

     def dependent_children
       @dependent_children ||= []
     end



.. _`Neo4j/ActiveNode#destroy`:

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



.. _`Neo4j/ActiveNode#destroyed?`:

**#destroyed?**
  Returns +true+ if the object was destroyed.

  .. code-block:: ruby

     def destroyed?
       @_deleted
     end



.. _`Neo4j/ActiveNode#eql?`:

**#eql?**
  

  .. code-block:: ruby

     def ==(other)
       other.class == self.class && other.id == id
     end



.. _`Neo4j/ActiveNode#exist?`:

**#exist?**
  

  .. code-block:: ruby

     def exist?
       _persisted_obj && _persisted_obj.exist?
     end



.. _`Neo4j/ActiveNode#freeze`:

**#freeze**
  

  .. code-block:: ruby

     def freeze
       @attributes.freeze
       self
     end



.. _`Neo4j/ActiveNode#frozen?`:

**#frozen?**
  

  .. code-block:: ruby

     def frozen?
       @attributes.frozen?
     end



.. _`Neo4j/ActiveNode#hash`:

**#hash**
  

  .. code-block:: ruby

     def hash
       id.hash
     end



.. _`Neo4j/ActiveNode#id`:

**#id**
  

  .. code-block:: ruby

     def id
       id = neo_id
       id.is_a?(Integer) ? id : nil
     end



.. _`Neo4j/ActiveNode#increment`:

**#increment**
  Increments a numeric attribute by a centain amount

  .. code-block:: ruby

     def increment(attribute, by = 1)
       self[attribute] ||= 0
       self[attribute] += by
       self
     end



.. _`Neo4j/ActiveNode#increment!`:

**#increment!**
  Convenience method to increment numeric attribute and #save at the same time

  .. code-block:: ruby

     def increment!(attribute, by = 1)
       increment(attribute, by).update_attribute(attribute, self[attribute])
     end



.. _`Neo4j/ActiveNode#init_on_load`:

**#init_on_load**
  called when loading the node from the database

  .. code-block:: ruby

     def init_on_load(persisted_node, properties)
       self.class.extract_association_attributes!(properties)
       @_persisted_obj = persisted_node
       changed_attributes && changed_attributes.clear
       @attributes = convert_and_assign_attributes(properties)
     end



.. _`Neo4j/ActiveNode#init_on_reload`:

**#init_on_reload**
  

  .. code-block:: ruby

     def init_on_reload(reloaded)
       @attributes = nil
       init_on_load(reloaded, reloaded.props)
     end



.. _`Neo4j/ActiveNode#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(args = nil)
       symbol_args = args.is_a?(Hash) ? args.symbolize_keys : args
       super(symbol_args)
     end



.. _`Neo4j/ActiveNode#inject_defaults!`:

**#inject_defaults!**
  

  .. code-block:: ruby

     def inject_defaults!(starting_props)
       return starting_props if self.class.declared_properties.declared_property_defaults.empty?
       self.class.declared_properties.inject_defaults!(self, starting_props || {})
     end



.. _`Neo4j/ActiveNode#inject_primary_key!`:

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



.. _`Neo4j/ActiveNode#inspect`:

**#inspect**
  

  .. code-block:: ruby

     def inspect
       attribute_descriptions = inspect_attributes.map do |key, value|
         "#{Neo4j::ANSI::CYAN}#{key}: #{Neo4j::ANSI::CLEAR}#{value.inspect}"
       end.join(', ')
     
       separator = ' ' unless attribute_descriptions.empty?
       "#<#{Neo4j::ANSI::YELLOW}#{self.class.name}#{Neo4j::ANSI::CLEAR}#{separator}#{attribute_descriptions}>"
     end



.. _`Neo4j/ActiveNode#labels`:

**#labels**
  

  .. code-block:: ruby

     def labels
       @_persisted_obj.labels
     end



.. _`Neo4j/ActiveNode#labels_for_create`:

**#labels_for_create**
  

  .. code-block:: ruby

     def labels_for_create
       self.class.mapped_label_names
     end



.. _`Neo4j/ActiveNode#marshal_dump`:

**#marshal_dump**
  

  .. code-block:: ruby

     def marshal_dump
       marshal_instance_variables.map(&method(:instance_variable_get))
     end



.. _`Neo4j/ActiveNode#marshal_load`:

**#marshal_load**
  

  .. code-block:: ruby

     def marshal_load(array)
       marshal_instance_variables.zip(array).each do |var, value|
         instance_variable_set(var, value)
       end
     end



.. _`Neo4j/ActiveNode#neo4j_obj`:

**#neo4j_obj**
  

  .. code-block:: ruby

     def neo4j_obj
       _persisted_obj || fail('Tried to access native neo4j object on a non persisted object')
     end



.. _`Neo4j/ActiveNode#neo_id`:

**#neo_id**
  

  .. code-block:: ruby

     def neo_id
       _persisted_obj ? _persisted_obj.neo_id : nil
     end



.. _`Neo4j/ActiveNode#new?`:

**#new?**
  Returns +true+ if the record hasn't been saved to Neo4j yet.

  .. code-block:: ruby

     def new_record?
       !_persisted_obj
     end



.. _`Neo4j/ActiveNode#new_record?`:

**#new_record?**
  Returns +true+ if the record hasn't been saved to Neo4j yet.

  .. code-block:: ruby

     def new_record?
       !_persisted_obj
     end



.. _`Neo4j/ActiveNode#pending_deferred_creations?`:

**#pending_deferred_creations?**
  

  .. code-block:: ruby

     def pending_deferred_creations?
       !deferred_create_cache.values.all?(&:empty?)
     end



.. _`Neo4j/ActiveNode#persisted?`:

**#persisted?**
  Returns +true+ if the record is persisted, i.e. it's not a new record and it was not destroyed

  .. code-block:: ruby

     def persisted?
       !new_record? && !destroyed?
     end



.. _`Neo4j/ActiveNode#props`:

**#props**
  

  .. code-block:: ruby

     def props
       attributes.reject { |_, v| v.nil? }.symbolize_keys
     end



.. _`Neo4j/ActiveNode#props_for_create`:

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



.. _`Neo4j/ActiveNode#props_for_persistence`:

**#props_for_persistence**
  

  .. code-block:: ruby

     def props_for_persistence
       _persisted_obj ? props_for_update : props_for_create
     end



.. _`Neo4j/ActiveNode#props_for_update`:

**#props_for_update**
  

  .. code-block:: ruby

     def props_for_update
       update_magic_properties
       changed_props = attributes.select { |k, _| changed_attributes.include?(k) }
       changed_props.symbolize_keys!
       inject_defaults!(changed_props)
       props_for_db(changed_props)
     end



.. _`Neo4j/ActiveNode#query_as`:

**#query_as**
  Returns a Query object with the current node matched the specified variable name

  .. code-block:: ruby

     def query_as(node_var)
       self.class.query_as(node_var, false).where("ID(#{node_var})" => self.neo_id)
     end



.. _`Neo4j/ActiveNode#read_attribute`:

**#read_attribute**
  

  .. code-block:: ruby

     def read_attribute(name)
       respond_to?(name) ? send(name) : nil
     end



.. _`Neo4j/ActiveNode#read_attribute_for_validation`:

**#read_attribute_for_validation**
  Implements the ActiveModel::Validation hook method.

  .. code-block:: ruby

     def read_attribute_for_validation(key)
       respond_to?(key) ? send(key) : self[key]
     end



.. _`Neo4j/ActiveNode#reload`:

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



.. _`Neo4j/ActiveNode#reload_from_database`:

**#reload_from_database**
  

  .. code-block:: ruby

     def reload_from_database
       reloaded = self.class.load_entity(neo_id)
       reloaded ? init_on_reload(reloaded._persisted_obj) : nil
     end



.. _`Neo4j/ActiveNode#reload_properties!`:

**#reload_properties!**
  

  .. code-block:: ruby

     def reload_properties!(properties)
       @attributes = nil
       convert_and_assign_attributes(properties)
     end



.. _`Neo4j/ActiveNode#remove_label`:

**#remove_label**
  Removes one or more labels
  Be careful, don't remove the label representing the Ruby class.

  .. code-block:: ruby

     def remove_label(*label)
       @_persisted_obj.remove_label(*label)
     end



.. _`Neo4j/ActiveNode#save`:

**#save**
  The validation process on save can be skipped by passing false. The regular Model#save method is
  replaced with this when the validations module is mixed in, which it is by default.

  .. code-block:: ruby

     def save(options = {})
       result = perform_validations(options) ? super : false
       if !result
         Neo4j::Transaction.current.failure if Neo4j::Transaction.current
       end
       result
     end



.. _`Neo4j/ActiveNode#save!`:

**#save!**
  Persist the object to the database.  Validations and Callbacks are included
  by default but validation can be disabled by passing :validate => false
  to #save!  Creates a new transaction.

  .. code-block:: ruby

     def save!(*args)
       save(*args) or fail(RecordInvalidError, self) # rubocop:disable Style/AndOr
     end



.. _`Neo4j/ActiveNode#send_props`:

**#send_props**
  

  .. code-block:: ruby

     def send_props(hash)
       return hash if hash.blank?
       hash.each { |key, value| send("#{key}=", value) }
     end



.. _`Neo4j/ActiveNode#serializable_hash`:

**#serializable_hash**
  

  .. code-block:: ruby

     def serializable_hash(*args)
       super.merge(id: id)
     end



.. _`Neo4j/ActiveNode#serialized_properties`:

**#serialized_properties**
  

  .. code-block:: ruby

     def serialized_properties
       self.class.serialized_properties
     end



.. _`Neo4j/ActiveNode#to_key`:

**#to_key**
  Returns an Enumerable of all (primary) key attributes
  or nil if model.persisted? is false

  .. code-block:: ruby

     def to_key
       _persisted_obj ? [id] : nil
     end



.. _`Neo4j/ActiveNode#touch`:

**#touch**
  :nodoc:

  .. code-block:: ruby

     def touch #:nodoc:
       run_callbacks(:touch) { super }
     end



.. _`Neo4j/ActiveNode#update`:

**#update**
  Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  If saving fails because the resource is invalid then false will be returned.

  .. code-block:: ruby

     def update(attributes)
       self.attributes = process_attributes(attributes)
       save
     end



.. _`Neo4j/ActiveNode#update!`:

**#update!**
  Same as {#update_attributes}, but raises an exception if saving fails.

  .. code-block:: ruby

     def update!(attributes)
       self.attributes = process_attributes(attributes)
       save!
     end



.. _`Neo4j/ActiveNode#update_attribute`:

**#update_attribute**
  Convenience method to set attribute and #save at the same time

  .. code-block:: ruby

     def update_attribute(attribute, value)
       send("#{attribute}=", value)
       self.save
     end



.. _`Neo4j/ActiveNode#update_attribute!`:

**#update_attribute!**
  Convenience method to set attribute and #save! at the same time

  .. code-block:: ruby

     def update_attribute!(attribute, value)
       send("#{attribute}=", value)
       self.save!
     end



.. _`Neo4j/ActiveNode#update_attributes`:

**#update_attributes**
  Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  If saving fails because the resource is invalid then false will be returned.

  .. code-block:: ruby

     def update(attributes)
       self.attributes = process_attributes(attributes)
       save
     end



.. _`Neo4j/ActiveNode#update_attributes!`:

**#update_attributes!**
  Same as {#update_attributes}, but raises an exception if saving fails.

  .. code-block:: ruby

     def update!(attributes)
       self.attributes = process_attributes(attributes)
       save!
     end



.. _`Neo4j/ActiveNode#valid?`:

**#valid?**
  

  .. code-block:: ruby

     def valid?(context = nil)
       context ||= (new_record? ? :create : :update)
       super(context)
       errors.empty?
     end



.. _`Neo4j/ActiveNode#wrapper`:

**#wrapper**
  Implements the Neo4j::Node#wrapper and Neo4j::Relationship#wrapper method
  so that we don't have to care if the node is wrapped or not.

  .. code-block:: ruby

     def wrapper
       self
     end



.. _`Neo4j/ActiveNode#write_attribute`:

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





