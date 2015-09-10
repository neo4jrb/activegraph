IdProperty
==========



This module makes it possible to use other IDs than the build it neo4j id (neo_id)


.. toctree::
   :maxdepth: 3
   :titlesonly:


   IdProperty/TypeMethods

   IdProperty/ClassMethods

   IdProperty/Accessor




Constants
---------





Files
-----



  * `lib/neo4j/active_node/id_property.rb:35 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/id_property.rb#L35>`_

  * `lib/neo4j/active_node/id_property/accessor.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/id_property/accessor.rb#L1>`_





Methods
-------



.. _`Neo4j/ActiveNode/IdProperty#default_properties`:

**#default_properties**
  

  .. code-block:: ruby

     def default_properties
       @default_properties ||= Hash.new(nil)
     end



.. _`Neo4j/ActiveNode/IdProperty#default_properties=`:

**#default_properties=**
  

  .. code-block:: ruby

     def default_properties=(properties)
       @default_property_value = properties[default_property_key]
     end



.. _`Neo4j/ActiveNode/IdProperty#default_property`:

**#default_property**
  

  .. code-block:: ruby

     def default_property(key)
       return nil unless key == default_property_key
       default_property_value
     end



.. _`Neo4j/ActiveNode/IdProperty#default_property_key`:

**#default_property_key**
  

  .. code-block:: ruby

     def default_property_key
       self.class.default_property_key
     end



.. _`Neo4j/ActiveNode/IdProperty#default_property_value`:

**#default_property_value**
  Returns the value of attribute default_property_value

  .. code-block:: ruby

     def default_property_value
       @default_property_value
     end





