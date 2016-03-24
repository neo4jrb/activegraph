ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/property.rb:111 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/property.rb#L111>`_





Methods
-------



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
       DeclaredProperty.new(name, options).tap do |prop|
         prop.register
         declared_properties.register(prop)
         yield name
         constraint_or_index(name, options)
       end
     end



.. _`Neo4j/Shared/Property/ClassMethods#declared_properties`:

**#declared_properties**
  

  .. code-block:: ruby

     def declared_properties
       @_declared_properties ||= DeclaredProperties.new(self)
     end



.. _`Neo4j/Shared/Property/ClassMethods#extract_association_attributes!`:

**#extract_association_attributes!**
  

  .. code-block:: ruby

     def extract_association_attributes!(props)
       props
     end



.. _`Neo4j/Shared/Property/ClassMethods#inherit_property`:

**#inherit_property**
  

  .. code-block:: ruby

     def inherit_property(name, attr_def, options = {})
       build_property(name, options) do |prop_name|
         attributes[prop_name] = attr_def
       end
     end



.. _`Neo4j/Shared/Property/ClassMethods#property`:

**#property**
  Defines a property on the class
  
  See active_attr gem for allowed options, e.g which type
  Notice, in Neo4j you don't have to declare properties before using them, see the neo4j-core api.

  .. code-block:: ruby

     def property(name, options = {})
       build_property(name, options) do |prop|
         attribute(prop)
       end
     end



.. _`Neo4j/Shared/Property/ClassMethods#undef_property`:

**#undef_property**
  

  .. code-block:: ruby

     def undef_property(name)
       undef_constraint_or_index(name)
       declared_properties.unregister(name)
       attribute_methods(name).each { |method| undef_method(method) }
     end





