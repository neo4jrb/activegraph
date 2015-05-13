ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/property.rb:123 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/property.rb#L123>`_





Methods
-------



.. _`Neo4j/Shared/Property/ClassMethods#attribute!`:

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



.. _`Neo4j/Shared/Property/ClassMethods#attributes_nil_hash`:

**#attributes_nil_hash**
  an extra call to a slow dependency method.

  .. hidden-code-block:: ruby

     def attributes_nil_hash
       declared_property_manager.attributes_nil_hash
     end



.. _`Neo4j/Shared/Property/ClassMethods#declared_property_manager`:

**#declared_property_manager**
  

  .. hidden-code-block:: ruby

     def declared_property_manager
       @_declared_property_manager ||= DeclaredPropertyManager.new(self)
     end



.. _`Neo4j/Shared/Property/ClassMethods#default_properties`:

**#default_properties**
  

  .. hidden-code-block:: ruby

     def default_properties
       @default_property ||= {}
     end



.. _`Neo4j/Shared/Property/ClassMethods#default_properties_keys`:

**#default_properties_keys**
  

  .. hidden-code-block:: ruby

     def default_properties_keys
       @default_properties_keys ||= default_properties.keys
     end



.. _`Neo4j/Shared/Property/ClassMethods#default_property`:

**#default_property**
  TODO: Move this to the DeclaredPropertyManager

  .. hidden-code-block:: ruby

     def default_property(name, &block)
       reset_default_properties(name) if default_properties.respond_to?(:size)
       default_properties[name] = block
     end



.. _`Neo4j/Shared/Property/ClassMethods#default_property_values`:

**#default_property_values**
  

  .. hidden-code-block:: ruby

     def default_property_values(instance)
       default_properties.each_with_object({}) do |(key, block), result|
         result[key] = block.call(instance)
       end
     end



.. _`Neo4j/Shared/Property/ClassMethods#property`:

**#property**
  Defines a property on the class
  
  See active_attr gem for allowed options, e.g which type
  Notice, in Neo4j you don't have to declare properties before using them, see the neo4j-core api.

  .. hidden-code-block:: ruby

     def property(name, options = {})
       prop = DeclaredProperty.new(name, options)
       prop.register
       declared_property_manager.register(prop)
     
       attribute(name, prop.options)
       constraint_or_index(name, options)
     end



.. _`Neo4j/Shared/Property/ClassMethods#reset_default_properties`:

**#reset_default_properties**
  

  .. hidden-code-block:: ruby

     def reset_default_properties(name_to_keep)
       default_properties.each_key do |property|
         @default_properties_keys = nil
         undef_method(property) unless property == name_to_keep
       end
       @default_properties_keys = nil
       @default_property = {}
     end



.. _`Neo4j/Shared/Property/ClassMethods#undef_property`:

**#undef_property**
  

  .. hidden-code-block:: ruby

     def undef_property(name)
       declared_property_manager.unregister(name)
       attribute_methods(name).each { |method| undef_method(method) }
       undef_constraint_or_index(name)
     end





