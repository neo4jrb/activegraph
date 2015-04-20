TypeConverters
==============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   TypeConverters/DateConverter

   TypeConverters/DateTimeConverter

   TypeConverters/TimeConverter

   TypeConverters/YAMLConverter

   TypeConverters/JSONConverter

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/type_converters.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/type_converters.rb#L2>`_





Methods
-------



.. _`Neo4j/Shared/TypeConverters#convert_properties_to`:

**#convert_properties_to**
  

  .. hidden-code-block:: ruby

     def convert_properties_to(medium, properties)
       converter = medium == :ruby ? :to_ruby : :to_db
       properties.each_pair do |attr, value|
         next if skip_conversion?(attr, value)
         properties[attr] = converted_property(primitive_type(attr.to_sym), value, converter)
       end
     end



.. _`Neo4j/Shared/TypeConverters.converters`:

**.converters**
  Returns the value of attribute converters

  .. hidden-code-block:: ruby

     def converters
       @converters
     end



.. _`Neo4j/Shared/TypeConverters.included`:

**.included**
  

  .. hidden-code-block:: ruby

     def included(_)
       return if @converters
       @converters = {}
       Neo4j::Shared::TypeConverters.constants.each do |constant_name|
         constant = Neo4j::Shared::TypeConverters.const_get(constant_name)
         register_converter(constant) if constant.respond_to?(:convert_type)
       end
     end



.. _`Neo4j/Shared/TypeConverters.register_converter`:

**.register_converter**
  

  .. hidden-code-block:: ruby

     def register_converter(converter)
       converters[converter.convert_type] = converter
     end



.. _`Neo4j/Shared/TypeConverters.to_other`:

**.to_other**
  

  .. hidden-code-block:: ruby

     def to_other(direction, value, type)
       fail "Unknown direction given: #{direction}" unless direction == :to_ruby || direction == :to_db
       found_converter = converters[type]
       found_converter ? found_converter.send(direction, value) : value
     end



.. _`Neo4j/Shared/TypeConverters.typecaster_for`:

**.typecaster_for**
  

  .. hidden-code-block:: ruby

     def typecaster_for(primitive_type)
       return nil if primitive_type.nil?
       converters.key?(primitive_type) ? converters[primitive_type] : nil
     end





