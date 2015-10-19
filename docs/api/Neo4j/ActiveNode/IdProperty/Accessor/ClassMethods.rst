ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/id_property/accessor.rb:26 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/id_property/accessor.rb#L26>`_





Methods
-------



.. _`Neo4j/ActiveNode/IdProperty/Accessor/ClassMethods#default_properties`:

**#default_properties**
  

  .. code-block:: ruby

     def default_properties
       @default_property ||= {}
     end



.. _`Neo4j/ActiveNode/IdProperty/Accessor/ClassMethods#default_properties_keys`:

**#default_properties_keys**
  

  .. code-block:: ruby

     def default_properties_keys
       @default_properties_keys ||= default_properties.keys
     end



.. _`Neo4j/ActiveNode/IdProperty/Accessor/ClassMethods#default_property`:

**#default_property**
  TODO: Move this to the DeclaredProperties

  .. code-block:: ruby

     def default_property(name, &block)
       reset_default_properties(name) if default_properties.respond_to?(:size)
       default_properties[name] = block
     end



.. _`Neo4j/ActiveNode/IdProperty/Accessor/ClassMethods#default_property_key`:

**#default_property_key**
  

  .. code-block:: ruby

     def default_property_key
       @default_property_key ||= default_properties_keys.first
     end



.. _`Neo4j/ActiveNode/IdProperty/Accessor/ClassMethods#default_property_values`:

**#default_property_values**
  

  .. code-block:: ruby

     def default_property_values(instance)
       default_properties.each_with_object({}) do |(key, block), result|
         result[key] = block.call(instance)
       end
     end



.. _`Neo4j/ActiveNode/IdProperty/Accessor/ClassMethods#reset_default_properties`:

**#reset_default_properties**
  

  .. code-block:: ruby

     def reset_default_properties(name_to_keep)
       default_properties.each_key do |property|
         @default_properties_keys = nil
         undef_method(property) unless property == name_to_keep
       end
       @default_properties_keys = nil
       @default_property = {}
     end





