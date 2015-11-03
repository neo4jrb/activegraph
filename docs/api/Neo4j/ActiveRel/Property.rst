Property
========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   Property/ClassMethods

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_rel/property.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/property.rb#L2>`_





Methods
-------



.. _`Neo4j/ActiveRel/Property#[]`:

**#[]**
  Returning nil when we get ActiveAttr::UnknownAttributeError from ActiveAttr

  .. code-block:: ruby

     def read_attribute(name)
       super(name)
     rescue ActiveAttr::UnknownAttributeError
       nil
     end



.. _`Neo4j/ActiveRel/Property#_persisted_obj`:

**#_persisted_obj**
  Returns the value of attribute _persisted_obj

  .. code-block:: ruby

     def _persisted_obj
       @_persisted_obj
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
       send_props(@relationship_props) unless @relationship_props.nil?
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
  Returning nil when we get ActiveAttr::UnknownAttributeError from ActiveAttr

  .. code-block:: ruby

     def read_attribute(name)
       super(name)
     rescue ActiveAttr::UnknownAttributeError
       nil
     end



.. _`Neo4j/ActiveRel/Property#rel_type`:

**#rel_type**
  

  .. code-block:: ruby

     def type
       self.class.type
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





