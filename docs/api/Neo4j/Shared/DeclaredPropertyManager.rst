DeclaredPropertyManager
=======================






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/declared_property_manager.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/declared_property_manager.rb#L2>`_





Methods
-------



.. _`Neo4j/Shared/DeclaredPropertyManager#attributes_nil_hash`:

**#attributes_nil_hash**
  

  .. hidden-code-block:: ruby

     def attributes_nil_hash
       @_attributes_nil_hash ||= {}.tap do |attr_hash|
         registered_properties.each_pair do |k, prop_obj|
           val = prop_obj.default_value
           attr_hash[k.to_s] = val
         end
       end.freeze
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#convert_properties_to`:

**#convert_properties_to**
  

  .. hidden-code-block:: ruby

     def convert_properties_to(obj, medium, properties)
       converter = medium == :ruby ? :to_ruby : :to_db
       properties.each_pair do |attr, value|
         next if skip_conversion?(obj, attr, value)
         properties[attr] = converted_property(primitive_type(attr.to_sym), value, converter)
       end
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#declared_property_defaults`:

**#declared_property_defaults**
  

  .. hidden-code-block:: ruby

     def declared_property_defaults
       @_default_property_values ||= {}
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#initialize`:

**#initialize**
  

  .. hidden-code-block:: ruby

     def initialize(klass)
       @klass = klass
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#klass`:

**#klass**
  Returns the value of attribute klass

  .. hidden-code-block:: ruby

     def klass
       @klass
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#magic_typecast_properties`:

**#magic_typecast_properties**
  

  .. hidden-code-block:: ruby

     def magic_typecast_properties
       @magic_typecast_properties ||= {}
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#magic_typecast_properties_keys`:

**#magic_typecast_properties_keys**
  

  .. hidden-code-block:: ruby

     def magic_typecast_properties_keys
       @magic_typecast_properties_keys ||= magic_typecast_properties.keys
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#register`:

**#register**
  

  .. hidden-code-block:: ruby

     def register(property)
       @_attributes_nil_hash = nil
       registered_properties[property.name] = property
       register_magic_typecaster(property) if property.magic_typecaster
       declared_property_defaults[property.name] = property.default_value if property.default_value
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#registered_properties`:

**#registered_properties**
  

  .. hidden-code-block:: ruby

     def registered_properties
       @_registered_properties ||= {}
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#serialize`:

**#serialize**
  

  .. hidden-code-block:: ruby

     def serialize(name, coder = JSON)
       @serialize ||= {}
       @serialize[name] = coder
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#serialized_properties`:

**#serialized_properties**
  

  .. hidden-code-block:: ruby

     def serialized_properties
       @serialize ||= {}
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#serialized_properties=`:

**#serialized_properties=**
  

  .. hidden-code-block:: ruby

     def serialized_properties=(serialize_hash)
       @serialized_property_keys = nil
       @serialize = serialize_hash.clone
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#serialized_properties_keys`:

**#serialized_properties_keys**
  

  .. hidden-code-block:: ruby

     def serialized_properties_keys
       @serialized_property_keys ||= serialized_properties.keys
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#unregister`:

**#unregister**
  

  .. hidden-code-block:: ruby

     def unregister(name)
       # might need to be include?(name.to_s)
       fail ArgumentError, "Argument `#{name}` not an attribute" if not registered_properties[name]
       declared_prop = registered_properties[name]
       registered_properties.delete(declared_prop)
       unregister_magic_typecaster(name)
       unregister_property_default(name)
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#upstream_primitives`:

**#upstream_primitives**
  The known mappings of declared properties and their primitive types.

  .. hidden-code-block:: ruby

     def upstream_primitives
       @upstream_primitives ||= {}
     end





