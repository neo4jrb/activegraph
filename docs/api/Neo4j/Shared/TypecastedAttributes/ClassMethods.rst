ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/typecasted_attributes.rb:73 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/typecasted_attributes.rb#L73>`_





Methods
-------



.. _`Neo4j/Shared/TypecastedAttributes/ClassMethods#_attribute_type`:

**#_attribute_type**
  Calculates an attribute type

  .. code-block:: ruby

     def _attribute_type(attribute_name)
       attributes[attribute_name].type || Object
     end



.. _`Neo4j/Shared/TypecastedAttributes/ClassMethods#inspect`:

**#inspect**
  Returns the class name plus its attribute names and types

  .. code-block:: ruby

     def inspect
       inspected_attributes = attribute_names.sort.map { |name| "#{name}: #{_attribute_type(name)}" }
       attributes_list = "(#{inspected_attributes.join(', ')})" unless inspected_attributes.empty?
       "#{name}#{attributes_list}"
     end



.. _`Neo4j/Shared/TypecastedAttributes/ClassMethods#typecast_attribute`:

**#typecast_attribute**
  

  .. code-block:: ruby

     def typecast_attribute(typecaster, value)
       Neo4j::Shared::TypeConverters.typecast_attribute(typecaster, value)
     end





