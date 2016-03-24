TypeConverters
==============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   TypeConverters/Boolean

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

   TypeConverters/EnumConverter

   TypeConverters/ObjectConverter

   

   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------



  * CONVERTERS



Files
-----



  * `lib/neo4j/shared/type_converters.rb:9 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/type_converters.rb#L9>`_





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



.. _`Neo4j/Shared/TypeConverters.converter_for`:

**.converter_for**
  

  .. code-block:: ruby

     def converter_for(type)
       type.respond_to?(:db_type) ? type : CONVERTERS[type]
     end



.. _`Neo4j/Shared/TypeConverters.formatted_for_db?`:

**.formatted_for_db?**
  Attempts to determine whether conversion should be skipped because the object is already of the anticipated output type.

  .. code-block:: ruby

     def formatted_for_db?(found_converter, value)
       return false unless found_converter.respond_to?(:db_type)
       found_converter.respond_to?(:converted) ? found_converter.converted?(value) : value.is_a?(found_converter.db_type)
     end



.. _`Neo4j/Shared/TypeConverters.included`:

**.included**
  

  .. code-block:: ruby

     def included(_)
       Neo4j::Shared::TypeConverters.constants.each do |constant_name|
         constant = Neo4j::Shared::TypeConverters.const_get(constant_name)
         register_converter(constant) if constant.respond_to?(:convert_type)
       end
     end



.. _`Neo4j/Shared/TypeConverters.register_converter`:

**.register_converter**
  

  .. code-block:: ruby

     def register_converter(converter)
       CONVERTERS[converter.convert_type] = converter
     end



.. _`Neo4j/Shared/TypeConverters.to_other`:

**.to_other**
  

  .. code-block:: ruby

     def to_other(direction, value, type)
       fail "Unknown direction given: #{direction}" unless direction == :to_ruby || direction == :to_db
       found_converter = converter_for(type)
       return value unless found_converter
       return value if direction == :to_db && formatted_for_db?(found_converter, value)
       found_converter.send(direction, value)
     end



.. _`Neo4j/Shared/TypeConverters.typecast_attribute`:

**.typecast_attribute**
  

  .. code-block:: ruby

     def typecast_attribute(typecaster, value)
       fail ArgumentError, "A typecaster must be given, #{typecaster} is invalid" unless typecaster.respond_to?(:to_ruby)
       return value if value.nil?
       typecaster.to_ruby(value)
     end



.. _`Neo4j/Shared/TypeConverters#typecast_attribute`:

**#typecast_attribute**
  

  .. code-block:: ruby

     def typecast_attribute(typecaster, value)
       Neo4j::Shared::TypeConverters.typecast_attribute(typecaster, value)
     end



.. _`Neo4j/Shared/TypeConverters#typecaster_for`:

**#typecaster_for**
  

  .. code-block:: ruby

     def typecaster_for(value)
       Neo4j::Shared::TypeConverters.typecaster_for(value)
     end



.. _`Neo4j/Shared/TypeConverters.typecaster_for`:

**.typecaster_for**
  

  .. code-block:: ruby

     def typecaster_for(primitive_type)
       return nil if primitive_type.nil?
       CONVERTERS[primitive_type]
     end





