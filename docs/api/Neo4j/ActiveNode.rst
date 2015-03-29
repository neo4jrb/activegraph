ActiveNode
==========




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   ActiveNode/Rels

   ActiveNode/Query

   ActiveNode/HasN

   ActiveNode/Scope

   ActiveNode/Labels

   ActiveNode/Property

   ActiveNode/Callbacks

   ActiveNode/Dependent

   ActiveNode/Initialize

   ActiveNode/Reflection

   ActiveNode/IdProperty

   ActiveNode/Validations

   ActiveNode/ClassMethods

   ActiveNode/OrmAdapter

   ActiveNode/Persistence

   ActiveNode/QueryMethods




Constants
---------



  * WRAPPED_CLASSES

  * WRAPPED_MODELS

  * MODELS_FOR_LABELS_CACHE

  * USES_CLASSNAME

  * ILLEGAL_PROPS



Files
-----



  * lib/neo4j/active_node.rb:23

  * lib/neo4j/active_node/rels.rb:1

  * lib/neo4j/active_node/query.rb:2

  * lib/neo4j/active_node/has_n.rb:1

  * lib/neo4j/active_node/scope.rb:3

  * lib/neo4j/active_node/labels.rb:2

  * lib/neo4j/active_node/property.rb:1

  * lib/neo4j/active_node/callbacks.rb:2

  * lib/neo4j/active_node/dependent.rb:2

  * lib/neo4j/active_node/reflection.rb:1

  * lib/neo4j/active_node/id_property.rb:1

  * lib/neo4j/active_node/validations.rb:2

  * lib/neo4j/active_node/orm_adapter.rb:4

  * lib/neo4j/active_node/persistence.rb:1

  * lib/neo4j/active_node/query_methods.rb:2

  * lib/neo4j/active_node/has_n/association.rb:4

  * lib/neo4j/active_node/query/query_proxy.rb:2

  * lib/neo4j/active_node/query/query_proxy_link.rb:2

  * lib/neo4j/active_node/query/query_proxy_methods.rb:2

  * lib/neo4j/active_node/query/query_proxy_enumerable.rb:2

  * lib/neo4j/active_node/dependent/association_methods.rb:2

  * lib/neo4j/active_node/dependent/query_proxy_methods.rb:2

  * lib/neo4j/active_node/query/query_proxy_find_in_batches.rb:2





Methods
-------


**#==**
  

  .. hidden-code-block:: ruby

     def ==(other)
       other.class == self.class && other.id == id
     end


**#[]**
  Returning nil when we get ActiveAttr::UnknownAttributeError from ActiveAttr

  .. hidden-code-block:: ruby

     def read_attribute(name)
       super(name)
     rescue ActiveAttr::UnknownAttributeError
       nil
     end


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


**#_persisted_obj**
  Returns the value of attribute _persisted_obj

  .. hidden-code-block:: ruby

     def _persisted_obj
       @_persisted_obj
     end


**#_rels_delegator**
  

  .. hidden-code-block:: ruby

     def _rels_delegator
       fail "Can't access relationship on a non persisted node" unless _persisted_obj
       _persisted_obj
     end


**#add_label**
  adds one or more labels

  .. hidden-code-block:: ruby

     def add_label(*label)
       @_persisted_obj.add_label(*label)
     end


**#as**
  Starts a new QueryProxy with the starting identifier set to the given argument and QueryProxy caller set to the node instance.
  This method does not exist within QueryProxy and can only be used to start a new chain.

  .. hidden-code-block:: ruby

     def as(node_var)
       self.class.query_proxy(node: node_var, caller: self).match_to(self)
     end


**#association_cache**
  Returns the current association cache. It is in the format
  { :association_name => { :hash_of_cypher_string => [collection] }}

  .. hidden-code-block:: ruby

     def association_cache
       @association_cache ||= {}
     end


**#association_instance_fetch**
  

  .. hidden-code-block:: ruby

     def association_instance_fetch(cypher_string, association_obj, &block)
       association_instance_get(cypher_string, association_obj) || association_instance_set(cypher_string, block.call, association_obj)
     end


**#association_instance_get**
  Returns the specified association instance if it responds to :loaded?, nil otherwise.

  .. hidden-code-block:: ruby

     def association_instance_get(cypher_string, association_obj)
       return if association_cache.nil? || association_cache.empty?
       lookup_obj = cypher_hash(cypher_string)
       reflection = association_reflection(association_obj)
       return if reflection.nil?
       association_cache[reflection.name] ? association_cache[reflection.name][lookup_obj] : nil
     end


**#association_instance_get_by_reflection**
  

  .. hidden-code-block:: ruby

     def association_instance_get_by_reflection(reflection_name)
       association_cache[reflection_name]
     end


**#association_instance_set**
  Caches an association result. Unlike ActiveRecord, which stores results in @association_cache using { :association_name => [collection_result] },
  ActiveNode stores it using { :association_name => { :hash_string_of_cypher => [collection_result] }}.
  This is necessary because an association name by itself does not take into account :where, :limit, :order, etc,... so it's prone to error.

  .. hidden-code-block:: ruby

     def association_instance_set(cypher_string, collection_result, association_obj)
       return collection_result if Neo4j::Transaction.current
       cache_key = cypher_hash(cypher_string)
       reflection = association_reflection(association_obj)
       return if reflection.nil?
       if @association_cache[reflection.name]
         @association_cache[reflection.name][cache_key] = collection_result
       else
         @association_cache[reflection.name] = {cache_key => collection_result}
       end
       collection_result
     end


**#association_query_proxy**
  

  .. hidden-code-block:: ruby

     def association_query_proxy(name, options = {})
       self.class.association_query_proxy(name, {start_object: self}.merge(options))
     end


**#association_reflection**
  

  .. hidden-code-block:: ruby

     def association_reflection(association_obj)
       self.class.reflect_on_association(association_obj.name)
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


**#called_by**
  Returns the value of attribute called_by

  .. hidden-code-block:: ruby

     def called_by
       @called_by
     end


**#called_by=**
  Sets the attribute called_by

  .. hidden-code-block:: ruby

     def called_by=(value)
       @called_by = value
     end


**#clear_association_cache**
  Clears out the association cache.

  .. hidden-code-block:: ruby

     def clear_association_cache #:nodoc:
       association_cache.clear if _persisted_obj
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
  :nodoc:

  .. hidden-code-block:: ruby

     def create_model #:nodoc:
       Neo4j::Transaction.run do
         run_callbacks(:create) { super }
       end
     end


**#create_or_update**
  :nodoc:

  .. hidden-code-block:: ruby

     def create_or_update #:nodoc:
       run_callbacks(:save) { super }
     end


**#cypher_hash**
  Uses the cypher generated by a QueryProxy object, complete with params, to generate a basic non-cryptographic hash
  for use in @association_cache.

  .. hidden-code-block:: ruby

     def cypher_hash(cypher_string)
       cypher_string.hash.abs
     end


**#default_properties**
  

  .. hidden-code-block:: ruby

     def default_properties
       @default_properties ||= Hash.new(nil)
       # keys = self.class.default_properties.keys
       # _persisted_obj.props.reject{|key| !keys.include?(key)}
     end


**#default_properties=**
  

  .. hidden-code-block:: ruby

     def default_properties=(properties)
       keys = self.class.default_properties.keys
       @default_properties = properties.select { |key| keys.include?(key) }
     end


**#default_property**
  

  .. hidden-code-block:: ruby

     def default_property(key)
       default_properties[key.to_sym]
     end


**#dependent_children**
  

  .. hidden-code-block:: ruby

     def dependent_children
       @dependent_children ||= []
     end


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


**#destroyed?**
  Returns +true+ if the object was destroyed.

  .. hidden-code-block:: ruby

     def destroyed?
       @_deleted || (!new_record? && !exist?)
     end


**#eql?**
  

  .. hidden-code-block:: ruby

     def ==(other)
       other.class == self.class && other.id == id
     end


**#exist?**
  

  .. hidden-code-block:: ruby

     def exist?
       _persisted_obj && _persisted_obj.exist?
     end


**#extract_writer_methods!**
  

  .. hidden-code-block:: ruby

     def extract_writer_methods!(attributes)
       {}.tap do |writer_method_props|
         attributes.each_key do |key|
           writer_method_props[key] = attributes.delete(key) if self.respond_to?("#{key}=")
         end
       end
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


**#hash**
  

  .. hidden-code-block:: ruby

     def hash
       id.hash
     end


**#id**
  

  .. hidden-code-block:: ruby

     def id
       id = neo_id
       id.is_a?(Integer) ? id : nil
     end


**#init_on_load**
  called when loading the node from the database

  .. hidden-code-block:: ruby

     def init_on_load(persisted_node, properties)
       self.class.extract_association_attributes!(properties)
       @_persisted_obj = persisted_node
       changed_attributes && changed_attributes.clear
       @attributes = attributes.merge(properties.stringify_keys)
       self.default_properties = properties
       @attributes = convert_properties_to :ruby, @attributes
     end


**#initialize**
  

  .. hidden-code-block:: ruby

     def initialize(attributes = {}, options = {})
       super(attributes, options)
     
       send_props(@relationship_props) if persisted? && !@relationship_props.nil?
     end


**#instantiate_object**
  

  .. hidden-code-block:: ruby

     def instantiate_object(field, values_with_empty_parameters)
       return nil if values_with_empty_parameters.all?(&:nil?)
       values = values_with_empty_parameters.collect { |v| v.nil? ? 1 : v }
       klass = field[:type]
       klass ? klass.new(*values) : values
     end


**#labels**
  

  .. hidden-code-block:: ruby

     def labels
       @_persisted_obj.labels
     end


**#magic_typecast_properties**
  

  .. hidden-code-block:: ruby

     def magic_typecast_properties
       self.class.magic_typecast_properties
     end


**#model_cache_key**
  

  .. hidden-code-block:: ruby

     def model_cache_key
       self.class.model_name.cache_key
     end


**#neo4j_obj**
  

  .. hidden-code-block:: ruby

     def neo4j_obj
       _persisted_obj || fail('Tried to access native neo4j object on a non persisted object')
     end


**#neo_id**
  

  .. hidden-code-block:: ruby

     def neo_id
       _persisted_obj ? _persisted_obj.neo_id : nil
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


**#perform_validations**
  

  .. hidden-code-block:: ruby

     def perform_validations(options = {})
       perform_validation = case options
                            when Hash
                              options[:validate] != false
                            end
     
       if perform_validation
         valid?(options.is_a?(Hash) ? options[:context] : nil)
       else
         true
       end
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


**#process_attributes**
  Gives support for Rails date_select, datetime_select, time_select helpers.

  .. hidden-code-block:: ruby

     def process_attributes(attributes = nil)
       multi_parameter_attributes = {}
       new_attributes = {}
       attributes.each_pair do |key, value|
         if match = key.match(/\A([^\(]+)\((\d+)([if])\)$/)
           found_key = match[1]
           index = match[2].to_i
           (multi_parameter_attributes[found_key] ||= {})[index] = value.empty? ? nil : value.send("to_#{$3}")
         else
           new_attributes[key] = value
         end
       end
     
       multi_parameter_attributes.empty? ? new_attributes : process_multiparameter_attributes(multi_parameter_attributes, new_attributes)
     end


**#process_multiparameter_attributes**
  

  .. hidden-code-block:: ruby

     def process_multiparameter_attributes(multi_parameter_attributes, new_attributes)
       multi_parameter_attributes.each_with_object(new_attributes) do |(key, values), attributes|
         values = (values.keys.min..values.keys.max).map { |i| values[i] }
     
         if (field = self.class.attributes[key.to_sym]).nil?
           fail MultiparameterAssignmentError, "error on assignment #{values.inspect} to #{key}"
         end
     
         attributes[key] = instantiate_object(field, values)
       end
     end


**#props**
  

  .. hidden-code-block:: ruby

     def props
       attributes.reject { |_, v| v.nil? }.symbolize_keys
     end


**#query_as**
  Returns a Query object with the current node matched the specified variable name

  .. hidden-code-block:: ruby

     def query_as(node_var)
       self.class.query_as(node_var).where("ID(#{node_var})" => self.neo_id)
     end


**#read_attribute**
  Returning nil when we get ActiveAttr::UnknownAttributeError from ActiveAttr

  .. hidden-code-block:: ruby

     def read_attribute(name)
       super(name)
     rescue ActiveAttr::UnknownAttributeError
       nil
     end


**#read_attribute_for_validation**
  Implements the ActiveModel::Validation hook method.

  .. hidden-code-block:: ruby

     def read_attribute_for_validation(key)
       respond_to?(key) ? send(key) : self[key]
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


**#remove_label**
  Removes one or more labels
  Be careful, don't remove the label representing the Ruby class.

  .. hidden-code-block:: ruby

     def remove_label(*label)
       @_persisted_obj.remove_label(*label)
     end


**#save**
  The validation process on save can be skipped by passing false. The regular Model#save method is
  replaced with this when the validations module is mixed in, which it is by default.

  .. hidden-code-block:: ruby

     def save(options = {})
       result = perform_validations(options) ? super : false
       if !result
         Neo4j::Transaction.current.failure if Neo4j::Transaction.current
       end
       result
     end


**#save!**
  Persist the object to the database.  Validations and Callbacks are included
  by default but validation can be disabled by passing :validate => false
  to #save!  Creates a new transaction.

  .. hidden-code-block:: ruby

     def save!(*args)
       fail RecordInvalidError, self unless save(*args)
     end


**#send_props**
  

  .. hidden-code-block:: ruby

     def send_props(hash)
       hash.each { |key, value| self.send("#{key}=", value) }
     end


**#serializable_hash**
  

  .. hidden-code-block:: ruby

     def serializable_hash(*args)
       super.merge(id: id)
     end


**#serialized_properties**
  

  .. hidden-code-block:: ruby

     def serialized_properties
       self.class.serialized_properties
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


**#to_key**
  Returns an Enumerable of all (primary) key attributes
  or nil if model.persisted? is false

  .. hidden-code-block:: ruby

     def to_key
       persisted? ? [id] : nil
     end


**#touch**
  :nodoc:

  .. hidden-code-block:: ruby

     def touch(*) #:nodoc:
       run_callbacks(:touch) { super }
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
  :nodoc:

  .. hidden-code-block:: ruby

     def update_model(*) #:nodoc:
       Neo4j::Transaction.run do
         run_callbacks(:update) { super }
       end
     end


**#valid?**
  

  .. hidden-code-block:: ruby

     def valid?(context = nil)
       context     ||= (new_record? ? :create : :update)
       super(context)
       errors.empty?
     end


**#validate_attributes!**
  Changes attributes hash to remove relationship keys
  Raises an error if there are any keys left which haven't been defined as properties on the model

  .. hidden-code-block:: ruby

     def validate_attributes!(attributes)
       invalid_properties = attributes.keys.map(&:to_s) - self.attributes.keys
       fail UndefinedPropertyError, "Undefined properties: #{invalid_properties.join(',')}" if invalid_properties.size > 0
     end


**#validate_persisted_for_association!**
  

  .. hidden-code-block:: ruby

     def validate_persisted_for_association!
       fail(Neo4j::ActiveNode::HasN::NonPersistedNodeError, 'Unable to create relationship with non-persisted nodes') unless self._persisted_obj
     end


**#wrapper**
  Implements the Neo4j::Node#wrapper and Neo4j::Relationship#wrapper method
  so that we don't have to care if the node is wrapped or not.

  .. hidden-code-block:: ruby

     def wrapper
       self
     end





