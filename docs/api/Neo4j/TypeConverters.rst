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
  

  .. hidden-code-block:: ruby

     def convert_properties_to(obj, medium, properties)
       converter = medium == :ruby ? :to_ruby : :to_db
       properties.each_pair do |attr, value|
         next if skip_conversion?(obj, attr, value)
         properties[attr] = converted_property(primitive_type(attr.to_sym), value, converter)
       end
     end





