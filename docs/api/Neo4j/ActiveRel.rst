ActiveRel
=========




.. toctree::
   :maxdepth: 3
   :titlesonly:


   ActiveRel/FrozenRelError

   

   

   ActiveRel/Types

   ActiveRel/Query

   ActiveRel/Property

   ActiveRel/Callbacks

   ActiveRel/Initialize

   ActiveRel/Validations

   ActiveRel/Persistence

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



  * lib/neo4j/active_rel.rb:4

  * lib/neo4j/active_rel/types.rb:2

  * lib/neo4j/active_rel/query.rb:1

  * lib/neo4j/active_rel/property.rb:1

  * lib/neo4j/active_rel/callbacks.rb:2

  * lib/neo4j/active_rel/initialize.rb:1

  * lib/neo4j/active_rel/validations.rb:2

  * lib/neo4j/active_rel/persistence.rb:1

  * lib/neo4j/active_rel/related_node.rb:1





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


**#_create_rel**
  

  .. hidden-code-block:: ruby

     def _create_rel(from_node, to_node, *args)
       props = self.class.default_property_values(self)
       props.merge!(args[0]) if args[0].is_a?(Hash)
       set_classname(props, true)
     
       if from_node.id.nil? || to_node.id.nil?
         fail RelCreateFailedError, "Unable to create relationship (id is nil). from_node: #{from_node}, to_node: #{to_node}"
       end
       _rel_creation_query(from_node, to_node, props)
     end


**#_persisted_obj**
  Returns the value of attribute _persisted_obj

  .. hidden-code-block:: ruby

     def _persisted_obj
       @_persisted_obj
     end


**#_rel_creation_query**
  

  .. hidden-code-block:: ruby

     def _rel_creation_query(from_node, to_node, props)
       Neo4j::Session.query.match(N1_N2_STRING)
         .where(ACTIVEREL_NODE_MATCH_STRING).params(n1_neo_id: from_node.neo_id, n2_neo_id: to_node.neo_id).break
         .send(create_method, "n1-[r:`#{type}`]->n2")
         .with('r').set(r: props).pluck(:r).first
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


**#clear_association_cache**
  

  .. hidden-code-block:: ruby

     def clear_association_cache; end


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


**#create_method**
  

  .. hidden-code-block:: ruby

     def create_method
       self.class.unique? ? :create_unique : :create
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


**#end_node**
  

  .. hidden-code-block:: ruby

     alias_method :end_node,   :to_node


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


**#initialize**
  

  .. hidden-code-block:: ruby

     def initialize(*args)
       load_nodes
       super
     end


**#instantiate_object**
  

  .. hidden-code-block:: ruby

     def instantiate_object(field, values_with_empty_parameters)
       return nil if values_with_empty_parameters.all?(&:nil?)
       values = values_with_empty_parameters.collect { |v| v.nil? ? 1 : v }
       klass = field[:type]
       klass ? klass.new(*values) : values
     end


**#load_nodes**
  

  .. hidden-code-block:: ruby

     def load_nodes(from_node = nil, to_node = nil)
       @from_node = RelatedNode.new(from_node)
       @to_node = RelatedNode.new(to_node)
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


**#save**
  

  .. hidden-code-block:: ruby

     def save(*args)
       unless self.persisted? || (from_node.respond_to?(:neo_id) && to_node.respond_to?(:neo_id))
         fail Neo4j::ActiveRel::Persistence::RelInvalidError, 'from_node and to_node must be node objects'
       end
       super(*args)
     end


**#save!**
  

  .. hidden-code-block:: ruby

     def save!(*args)
       fail RelInvalidError, self unless save(*args)
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


**#start_node**
  

  .. hidden-code-block:: ruby

     alias_method :start_node, :from_node


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


**#type**
  

  .. hidden-code-block:: ruby

     def type
       self.class._type
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


**#validate_node_classes!**
  

  .. hidden-code-block:: ruby

     def validate_node_classes!
       [from_node, to_node].each do |node|
         type = from_node == node ? :_from_class : :_to_class
         type_class = self.class.send(type)
     
         next if [:any, false].include?(type_class)
     
         fail ModelClassInvalidError, "Node class was #{node.class}, expected #{type_class}" unless node.is_a?(type_class.to_s.constantize)
       end
     end


**#wrapper**
  Implements the Neo4j::Node#wrapper and Neo4j::Relationship#wrapper method
  so that we don't have to care if the node is wrapped or not.

  .. hidden-code-block:: ruby

     def wrapper
       self
     end





