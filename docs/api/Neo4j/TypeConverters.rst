TypeConverters
==============




.. toctree::
   :maxdepth: 3
   :titlesonly:





Constants
---------





Files
-----



  * lib/neo4j/type_converters.rb:2





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


**#skip_conversion?**
  Returns true if the property isn't defined in the model or it's both nil and unchanged.

  .. hidden-code-block:: ruby

     def skip_conversion?(attr, value)
       !self.class.attributes[attr] || (value.nil? && !changed_attributes.key?(attr))
     end





