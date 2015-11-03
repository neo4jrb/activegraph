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
       declared_properties.attributes_nil_hash
     end



.. _`Neo4j/Shared/Property/ClassMethods#build_property`:

**#build_property**
  

  .. code-block:: ruby

     def build_property(name, options)
       prop = DeclaredProperty.new(name, options)
       prop.register
       declared_properties.register(prop)
       yield prop
       constraint_or_index(name, options)
     end



.. _`Neo4j/Shared/Property/ClassMethods#declared_properties`:

**#declared_properties**
  

  .. code-block:: ruby

     def declared_properties
       @_declared_properties ||= DeclaredProperties.new(self)
     end



.. _`Neo4j/Shared/Property/ClassMethods#inherit_property`:

**#inherit_property**
  

  .. code-block:: ruby

     def inherit_property(name, active_attr, options = {})
       build_property(name, options) do |prop|
         attributes[prop.name.to_s] = active_attr
       end
     end



.. _`Neo4j/Shared/Property/ClassMethods#inherited`:

**#inherited**
  

  .. code-block:: ruby

     def inherited(other)
       self.declared_properties.registered_properties.each_pair do |prop_key, prop_def|
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
       build_property(name, options) do |prop|
         attribute(name, prop.options)
       end
     end



.. _`Neo4j/Shared/Property/ClassMethods#undef_property`:

**#undef_property**
  

  .. code-block:: ruby

     def undef_property(name)
       declared_properties.unregister(name)
       attribute_methods(name).each { |method| undef_method(method) }
       undef_constraint_or_index(name)
     end





