TypeConverters
==============






.. toctree::
   :maxdepth: 3
   :titlesonly:





Constants
---------





Files
-----



  * `lib/neo4j/type_converters.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/type_converters.rb#L2>`_





Methods
-------



.. _`Neo4j/TypeConverters#convert_properties_to`:

**#convert_properties_to**
  Modifies a hash's values to be of types acceptable to Neo4j or matching what the user defined using `type` in property definitions.

  .. code-block:: ruby

     def convert_properties_to(obj, medium, properties)
       direction = medium == :ruby ? :to_ruby : :to_db
       properties.each_pair do |key, value|
         next if skip_conversion?(obj, key, value)
         properties[key] = convert_property(key, value, direction)
       end
     end



.. _`Neo4j/TypeConverters#convert_property`:

**#convert_property**
  Converts a single property from its current format to its db- or Ruby-expected output type.

  .. code-block:: ruby

     def convert_property(key, value, direction)
       converted_property(primitive_type(key.to_sym), value, direction)
     end





