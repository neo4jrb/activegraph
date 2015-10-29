Accessor
========



Provides get/set of the Id Property values.
Some methods


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   Accessor/ClassMethods




Constants
---------





Files
-----



  * `lib/neo4j/active_node/id_property/accessor.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/id_property/accessor.rb#L4>`_





Methods
-------



.. _`Neo4j/ActiveNode/IdProperty/Accessor#default_properties`:

**#default_properties**
  

  .. code-block:: ruby

     def default_properties
       @default_properties ||= Hash.new(nil)
     end



.. _`Neo4j/ActiveNode/IdProperty/Accessor#default_properties=`:

**#default_properties=**
  

  .. code-block:: ruby

     def default_properties=(properties)
       @default_property_value = properties[default_property_key]
     end



.. _`Neo4j/ActiveNode/IdProperty/Accessor#default_property`:

**#default_property**
  

  .. code-block:: ruby

     def default_property(key)
       return nil unless key == default_property_key
       default_property_value
     end



.. _`Neo4j/ActiveNode/IdProperty/Accessor#default_property_key`:

**#default_property_key**
  

  .. code-block:: ruby

     def default_property_key
       self.class.default_property_key
     end



.. _`Neo4j/ActiveNode/IdProperty/Accessor#default_property_value`:

**#default_property_value**
  Returns the value of attribute default_property_value

  .. code-block:: ruby

     def default_property_value
       @default_property_value
     end





