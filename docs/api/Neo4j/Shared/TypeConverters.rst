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


**#convert_properties_to**
  

  .. hidden-code-block:: ruby

     def convert_properties_to(medium, properties)
       converter = medium == :ruby ? :to_ruby : :to_db
     
       properties.each_with_object({}) do |(attr, value), new_attributes|
         next new_attributes if skip_conversion?(attr, value)
         new_attributes[attr] = converted_property(primitive_type(attr.to_sym), value, converter)
       end
     end


**#converted_property**
  

  .. hidden-code-block:: ruby

     def converted_property(type, value, converter)
       TypeConverters.converters[type].nil? ? value : TypeConverters.to_other(converter, value, type)
     end


**#converters**
  Returns the value of attribute converters

  .. hidden-code-block:: ruby

     def converters
       @converters
     end


**#included**
  

  .. hidden-code-block:: ruby

     def included(_)
       return if @converters
       @converters = {}
       Neo4j::Shared::TypeConverters.constants.each do |constant_name|
         constant = Neo4j::Shared::TypeConverters.const_get(constant_name)
         register_converter(constant) if constant.respond_to?(:convert_type)
       end
     end


**#primitive_type**
  If the attribute is to be typecast using a custom converter, which converter should it use? If no, returns the type to find a native serializer.

  .. hidden-code-block:: ruby

     def primitive_type(attr)
       case
       when serialized_properties.key?(attr)
         serialized_properties[attr]
       when magic_typecast_properties.key?(attr)
         self.class.magic_typecast_properties[attr]
       else
         self.class._attribute_type(attr)
       end
     end


**#register_converter**
  

  .. hidden-code-block:: ruby

     def register_converter(converter)
       converters[converter.convert_type] = converter
     end


**#skip_conversion?**
  Returns true if the property isn't defined in the model or it's both nil and unchanged.

  .. hidden-code-block:: ruby

     def skip_conversion?(attr, value)
       !self.class.attributes[attr] || (value.nil? && !changed_attributes.key?(attr))
     end


**#to_other**
  

  .. hidden-code-block:: ruby

     def to_other(direction, value, type)
       fail "Unknown direction given: #{direction}" unless direction == :to_ruby || direction == :to_db
       found_converter = converters[type]
       found_converter ? found_converter.send(direction, value) : value
     end


**#typecaster_for**
  

  .. hidden-code-block:: ruby

     def typecaster_for(primitive_type)
       converters.key?(primitive_type) ? converters[primitive_type] : nil
     end





