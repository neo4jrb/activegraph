TypeConverters
==============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   TypeConverters/BaseConverter

   TypeConverters/IntegerConverter

   TypeConverters/FloatConverter

   TypeConverters/BigDecimalConverter

   TypeConverters/StringConverter

   TypeConverters/BooleanConverter

   TypeConverters/DateConverter

   TypeConverters/DateTimeConverter

   TypeConverters/TimeConverter

   TypeConverters/YAMLConverter

   TypeConverters/JSONConverter

   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/type_converters.rb:7 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/type_converters.rb#L7>`_





Methods
-------



.. _`Neo4j/Shared/TypeConverters#convert_properties_to`:

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



.. _`Neo4j/Shared/TypeConverters#convert_property`:

**#convert_property**
  Converts a single property from its current format to its db- or Ruby-expected output type.

  .. code-block:: ruby

     def convert_property(key, value, direction)
       converted_property(primitive_type(key.to_sym), value, direction)
     end



.. _`Neo4j/Shared/TypeConverters.converters`:

**.converters**
  Returns the value of attribute converters

  .. code-block:: ruby

     def converters
       @converters
     end



.. _`Neo4j/Shared/TypeConverters.formatted_for_db?`:

**.formatted_for_db?**
  Attempts to determine whether conversion should be skipped because the object is already of the anticipated output type.

  .. code-block:: ruby

     def formatted_for_db?(found_converter, value)
       return false unless found_converter.respond_to?(:db_type)
       if found_converter.respond_to?(:converted)
         found_converter.converted?(value)
       else
         value.is_a?(found_converter.db_type)
       end
     end



.. _`Neo4j/Shared/TypeConverters.included`:

**.included**
  

  .. code-block:: ruby

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
  

  .. code-block:: ruby

     def register_converter(converter)
       converters[converter.convert_type] = converter
     end



.. _`Neo4j/Shared/TypeConverters.to_other`:

**.to_other**
  

  .. code-block:: ruby

     def to_other(direction, value, type)
       fail "Unknown direction given: #{direction}" unless direction == :to_ruby || direction == :to_db
       found_converter = converters[type]
       return value unless found_converter
       return value if direction == :to_db && formatted_for_db?(found_converter, value)
       found_converter.send(direction, value)
     end



.. _`Neo4j/Shared/TypeConverters.typecaster_for`:

**.typecaster_for**
  

  .. code-block:: ruby

     def typecaster_for(primitive_type)
       return nil if primitive_type.nil?
       converters.key?(primitive_type) ? converters[primitive_type] : nil
     end





