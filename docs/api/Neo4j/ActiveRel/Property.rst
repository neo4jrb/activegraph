Property
========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   Property/ClassMethods

   

   




Constants
---------



  * DATE_KEY_REGEX

  * DEPRECATED_OBJECT_METHODS



Files
-----



  * `lib/neo4j/active_rel/property.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/property.rb#L4>`_





Methods
-------



.. _`Neo4j/ActiveRel/Property#==`:

**#==**
  Performs equality checking on the result of attributes and its type.

  .. code-block:: ruby

     def ==(other)
       return false unless other.instance_of? self.class
       attributes == other.attributes
     end



.. _`Neo4j/ActiveRel/Property#[]`:

**#[]**
  

  .. code-block:: ruby

     def read_attribute(name)
       respond_to?(name) ? send(name) : nil
     end



.. _`Neo4j/ActiveRel/Property#[]=`:

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



.. _`Neo4j/ActiveRel/Property#_persisted_obj`:

**#_persisted_obj**
  Returns the value of attribute _persisted_obj

  .. code-block:: ruby

     def _persisted_obj
       @_persisted_obj
     end



.. _`Neo4j/ActiveRel/Property#assign_attributes`:

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



.. _`Neo4j/ActiveRel/Property#attribute_before_type_cast`:

**#attribute_before_type_cast**
  Read the raw attribute value

  .. code-block:: ruby

     def attribute_before_type_cast(name)
       @attributes ||= {}
       @attributes[name.to_s]
     end



.. _`Neo4j/ActiveRel/Property#attributes`:

**#attributes**
  Returns a Hash of all attributes

  .. code-block:: ruby

     def attributes
       attributes_map { |name| send name }
     end



.. _`Neo4j/ActiveRel/Property#attributes=`:

**#attributes=**
  Mass update a model's attributes

  .. code-block:: ruby

     def attributes=(new_attributes)
       assign_attributes(new_attributes)
     end



.. _`Neo4j/ActiveRel/Property#creates_unique_option`:

**#creates_unique_option**
  

  .. code-block:: ruby

     def creates_unique_option
       self.class.creates_unique_option
     end



.. _`Neo4j/ActiveRel/Property#end_node`:

**#end_node**
  

  .. code-block:: ruby

     alias_method :end_node,   :to_node



.. _`Neo4j/ActiveRel/Property#from_node_neo_id`:

**#from_node_neo_id**
  

  .. code-block:: ruby

     alias_method :from_node_neo_id, :start_node_neo_id



.. _`Neo4j/ActiveRel/Property#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(attributes = nil)
       super(attributes)
     end



.. _`Neo4j/ActiveRel/Property#inject_defaults!`:

**#inject_defaults!**
  

  .. code-block:: ruby

     def inject_defaults!(starting_props)
       return starting_props if self.class.declared_properties.declared_property_defaults.empty?
       self.class.declared_properties.inject_defaults!(self, starting_props || {})
     end



.. _`Neo4j/ActiveRel/Property#inspect`:

**#inspect**
  

  .. code-block:: ruby

     def inspect
       attribute_descriptions = inspect_attributes.map do |key, value|
         "#{Neo4j::ANSI::CYAN}#{key}: #{Neo4j::ANSI::CLEAR}#{value.inspect}"
       end.join(', ')
     
       separator = ' ' unless attribute_descriptions.empty?
       "#<#{Neo4j::ANSI::YELLOW}#{self.class.name}#{Neo4j::ANSI::CLEAR}#{separator}#{attribute_descriptions}>"
     end



.. _`Neo4j/ActiveRel/Property#read_attribute`:

**#read_attribute**
  

  .. code-block:: ruby

     def read_attribute(name)
       respond_to?(name) ? send(name) : nil
     end



.. _`Neo4j/ActiveRel/Property#rel_type`:

**#rel_type**
  

  .. code-block:: ruby

     def type
       self.class.type
     end



.. _`Neo4j/ActiveRel/Property#reload_properties!`:

**#reload_properties!**
  

  .. code-block:: ruby

     def reload_properties!(properties)
       @attributes = nil
       convert_and_assign_attributes(properties)
     end



.. _`Neo4j/ActiveRel/Property#send_props`:

**#send_props**
  

  .. code-block:: ruby

     def send_props(hash)
       return hash if hash.blank?
       hash.each { |key, value| send("#{key}=", value) }
     end



.. _`Neo4j/ActiveRel/Property#start_node`:

**#start_node**
  

  .. code-block:: ruby

     alias_method :start_node, :from_node



.. _`Neo4j/ActiveRel/Property#to_node_neo_id`:

**#to_node_neo_id**
  

  .. code-block:: ruby

     alias_method :to_node_neo_id,   :end_node_neo_id



.. _`Neo4j/ActiveRel/Property#type`:

**#type**
  

  .. code-block:: ruby

     def type
       self.class.type
     end



.. _`Neo4j/ActiveRel/Property#write_attribute`:

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





