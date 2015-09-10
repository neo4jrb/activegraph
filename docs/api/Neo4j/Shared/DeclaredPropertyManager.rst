DeclaredPropertyManager
=======================



The DeclaredPropertyuManager holds details about objects created as a result of calling the #property
class method on a class that includes Neo4j::ActiveNode or Neo4j::ActiveRel. There are many options
that are referenced frequently, particularly during load and save, so this provides easy access and
a way of separating behavior from the general Active{obj} modules.

See Neo4j::Shared::DeclaredProperty for definitions of the property objects themselves.


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/declared_property_manager.rb:8 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/declared_property_manager.rb#L8>`_





Methods
-------



.. _`Neo4j/Shared/DeclaredPropertyManager#attributes_nil_hash`:

**#attributes_nil_hash**
  During object wrap, a hash is needed that contains each declared property with a nil value.
  The active_attr dependency is capable of providing this but it is expensive and calculated on the fly
  each time it is called. Rather than rely on that, we build this progressively as properties are registered.
  When the node or rel is loaded, this is used as a template.

  .. code-block:: ruby

     def attributes_nil_hash
       @_attributes_nil_hash ||= {}.tap do |attr_hash|
         registered_properties.each_pair do |k, prop_obj|
           val = prop_obj.default_value
           attr_hash[k.to_s] = val
         end
       end.freeze
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#attributes_string_map`:

**#attributes_string_map**
  During object wrapping, a props hash is built with string keys but Neo4j-core provides symbols.
  Rather than a `to_s` or `symbolize_keys` during every load, we build a map of symbol-to-string
  to speed up the process. This increases memory used by the gem but reduces object allocation and GC, so it is faster
  in practice.

  .. code-block:: ruby

     def attributes_string_map
       @_attributes_string_map ||= {}.tap do |attr_hash|
         attributes_nil_hash.each_key { |k| attr_hash[k.to_sym] = k }
       end.freeze
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#convert_properties_to`:

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



.. _`Neo4j/Shared/DeclaredPropertyManager#convert_property`:

**#convert_property**
  Converts a single property from its current format to its db- or Ruby-expected output type.

  .. code-block:: ruby

     def convert_property(key, value, direction)
       converted_property(primitive_type(key.to_sym), value, direction)
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#declared_property_defaults`:

**#declared_property_defaults**
  The :default option in Neo4j::ActiveNode#property class method allows for setting a default value instead of
  nil on declared properties. This holds those values.

  .. code-block:: ruby

     def declared_property_defaults
       @_default_property_values ||= {}
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#initialize`:

**#initialize**
  Each class that includes Neo4j::ActiveNode or Neo4j::ActiveRel gets one instance of this class.

  .. code-block:: ruby

     def initialize(klass)
       @klass = klass
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#klass`:

**#klass**
  Returns the value of attribute klass

  .. code-block:: ruby

     def klass
       @klass
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#magic_typecast_properties`:

**#magic_typecast_properties**
  

  .. code-block:: ruby

     def magic_typecast_properties
       @magic_typecast_properties ||= {}
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#magic_typecast_properties_keys`:

**#magic_typecast_properties_keys**
  

  .. code-block:: ruby

     def magic_typecast_properties_keys
       @magic_typecast_properties_keys ||= magic_typecast_properties.keys
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#register`:

**#register**
  #property on an ActiveNode or ActiveRel class. The DeclaredProperty has specifics about the property, but registration
  makes the management object aware of it. This is necessary for type conversion, defaults, and inclusion in the nil and string hashes.

  .. code-block:: ruby

     def register(property)
       @_attributes_nil_hash = nil
       @_attributes_string_map = nil
       registered_properties[property.name] = property
       register_magic_typecaster(property) if property.magic_typecaster
       declared_property_defaults[property.name] = property.default_value if !property.default_value.nil?
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#registered_properties`:

**#registered_properties**
  

  .. code-block:: ruby

     def registered_properties
       @_registered_properties ||= {}
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#serialize`:

**#serialize**
  

  .. code-block:: ruby

     def serialize(name, coder = JSON)
       @serialize ||= {}
       @serialize[name] = coder
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#serialized_properties`:

**#serialized_properties**
  

  .. code-block:: ruby

     def serialized_properties
       @serialize ||= {}
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#serialized_properties=`:

**#serialized_properties=**
  

  .. code-block:: ruby

     def serialized_properties=(serialize_hash)
       @serialized_property_keys = nil
       @serialize = serialize_hash.clone
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#serialized_properties_keys`:

**#serialized_properties_keys**
  

  .. code-block:: ruby

     def serialized_properties_keys
       @serialized_property_keys ||= serialized_properties.keys
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#string_key`:

**#string_key**
  but when this happens many times while loading many objects, it results in a surprisingly significant slowdown.
  The branching logic handles what happens if a property can't be found.
  The first option attempts to find it in the existing hash.
  The second option checks whether the key is the class's id property and, if it is, the string hash is rebuilt with it to prevent
  future lookups.
  The third calls `to_s`. This would happen if undeclared properties are found on the object. We could add them to the string map
  but that would result in unchecked, un-GCed memory consumption. In the event that someone is adding properties dynamically,
  maybe through user input, this would be bad.

  .. code-block:: ruby

     def string_key(k)
       attributes_string_map[k] || string_map_id_property(k) || k.to_s
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#unregister`:

**#unregister**
  

  .. code-block:: ruby

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

  .. code-block:: ruby

     def upstream_primitives
       @upstream_primitives ||= {}
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#value_for_db`:

**#value_for_db**
  

  .. code-block:: ruby

     def value_for_db(key, value)
       return value unless registered_properties[key]
       convert_property(key, value, :to_db)
     end



.. _`Neo4j/Shared/DeclaredPropertyManager#value_for_ruby`:

**#value_for_ruby**
  

  .. code-block:: ruby

     def value_for_ruby(key, value)
       return unless registered_properties[key]
       convert_property(key, value, :to_ruby)
     end





