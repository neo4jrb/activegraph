ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/property.rb:108 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/property.rb#L108>`_





Methods
-------



.. _`Neo4j/Shared/Property/ClassMethods#attribute!`:

**#attribute!**
  

  .. code-block:: ruby

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

  .. code-block:: ruby

     def attributes_nil_hash
       declared_property_manager.attributes_nil_hash
     end



.. _`Neo4j/Shared/Property/ClassMethods#declared_property_manager`:

**#declared_property_manager**
  

  .. code-block:: ruby

     def declared_property_manager
       @_declared_property_manager ||= DeclaredPropertyManager.new(self)
     end



.. _`Neo4j/Shared/Property/ClassMethods#inherited`:

**#inherited**
  

  .. code-block:: ruby

     def inherited(other)
       self.declared_property_manager.registered_properties.each_pair do |prop_key, prop_def|
         other.property(prop_key, prop_def.options)
       end
       super
     end



.. _`Neo4j/Shared/Property/ClassMethods#property`:

**#property**
  Defines a property on the class
  
  See active_attr gem for allowed options, e.g which type
  Notice, in Neo4j you don't have to declare properties before using them, see the neo4j-core api.

  .. code-block:: ruby

     def property(name, options = {})
       prop = DeclaredProperty.new(name, options)
       prop.register
       declared_property_manager.register(prop)
     
       attribute(name, prop.options)
       constraint_or_index(name, options)
     end



.. _`Neo4j/Shared/Property/ClassMethods#undef_property`:

**#undef_property**
  

  .. code-block:: ruby

     def undef_property(name)
       declared_property_manager.unregister(name)
       attribute_methods(name).each { |method| undef_method(method) }
       undef_constraint_or_index(name)
     end





