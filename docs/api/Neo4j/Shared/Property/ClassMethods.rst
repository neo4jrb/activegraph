ClassMethods
============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * lib/neo4j/shared/property.rb:116





Methods
-------


**#attribute!**
  

  .. hidden-code-block:: ruby

     def attribute!(name, options = {})
       super(name, options)
       define_method("#{name}=") do |value|
         typecast_value = typecast_attribute(_attribute_typecaster(name), value)
         send("#{name}_will_change!") unless typecast_value == read_attribute(name)
         super(value)
       end
     end


**#check_illegal_prop**
  

  .. hidden-code-block:: ruby

     def check_illegal_prop(name)
       fail IllegalPropertyError, "#{name} is an illegal property" if ILLEGAL_PROPS.include?(name.to_s)
     end


**#constraint_or_index**
  

  .. hidden-code-block:: ruby

     def constraint_or_index(name, options)
       # either constraint or index, do not set both
       if options[:constraint]
         fail "unknown constraint type #{options[:constraint]}, only :unique supported" if options[:constraint] != :unique
         constraint(name, type: :unique)
       elsif options[:index]
         fail "unknown index type #{options[:index]}, only :exact supported" if options[:index] != :exact
         index(name, options) if options[:index] == :exact
       end
     end


**#default_properties**
  

  .. hidden-code-block:: ruby

     def default_properties
       @default_property ||= {}
     end


**#default_property**
  

  .. hidden-code-block:: ruby

     def default_property(name, &block)
       reset_default_properties(name) if default_properties.respond_to?(:size)
       default_properties[name] = block
     end


**#default_property_values**
  

  .. hidden-code-block:: ruby

     def default_property_values(instance)
       default_properties.each_with_object({}) do |(key, block), result|
         result[key] = block.call(instance)
       end
     end


**#magic_properties**
  Tweaks properties

  .. hidden-code-block:: ruby

     def magic_properties(name, options)
       magic_typecast(name, options)
       type_converter(options)
       options[:type] ||= DateTime if name.to_sym == :created_at || name.to_sym == :updated_at
     
       # ActiveAttr does not handle "Time", Rails and Neo4j.rb 2.3 did
       # Convert it to DateTime in the interest of consistency
       options[:type] = DateTime if options[:type] == Time
     end


**#magic_typecast**
  

  .. hidden-code-block:: ruby

     def magic_typecast(name, options)
       typecaster = Neo4j::Shared::TypeConverters.typecaster_for(options[:type])
       return unless typecaster && typecaster.respond_to?(:primitive_type)
       magic_typecast_properties[name] = options[:type]
       options[:type] = typecaster.primitive_type
       options[:typecaster] = typecaster
     end


**#magic_typecast_properties**
  

  .. hidden-code-block:: ruby

     def magic_typecast_properties
       @magic_typecast_properties ||= {}
     end


**#property**
  Defines a property on the class
  
  See active_attr gem for allowed options, e.g which type
  Notice, in Neo4j you don't have to declare properties before using them, see the neo4j-core api.

  .. hidden-code-block:: ruby

     def property(name, options = {})
       check_illegal_prop(name)
       magic_properties(name, options)
       attribute(name, options)
       constraint_or_index(name, options)
     end


**#reset_default_properties**
  

  .. hidden-code-block:: ruby

     def reset_default_properties(name_to_keep)
       default_properties.each_key do |property|
         undef_method(property) unless property == name_to_keep
       end
       @default_property = {}
     end


**#type_converter**
  

  .. hidden-code-block:: ruby

     def type_converter(options)
       converter = options[:serializer]
       return unless converter
       options[:type]        = converter.convert_type
       options[:typecaster]  = ActiveAttr::Typecasting::ObjectTypecaster.new
       Neo4j::Shared::TypeConverters.register_converter(converter)
     end


**#undef_property**
  

  .. hidden-code-block:: ruby

     def undef_property(name)
       fail ArgumentError, "Argument `#{name}` not an attribute" if not attribute_names.include?(name.to_s)
     
       attribute_methods(name).each { |method| undef_method(method) }
     
       undef_constraint_or_index(name)
     end





