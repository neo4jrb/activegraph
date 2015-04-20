ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/serialized_properties.rb:18 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/serialized_properties.rb#L18>`_





Methods
-------



.. _`Neo4j/Shared/SerializedProperties/ClassMethods#serialize`:

**#serialize**
  

  .. hidden-code-block:: ruby

     def serialize(name, coder = JSON)
       @serialize ||= {}
       @serialize[name] = coder
     end



.. _`Neo4j/Shared/SerializedProperties/ClassMethods#serialized_properties`:

**#serialized_properties**
  

  .. hidden-code-block:: ruby

     def serialized_properties
       @serialize ||= {}
     end



.. _`Neo4j/Shared/SerializedProperties/ClassMethods#serialized_properties=`:

**#serialized_properties=**
  

  .. hidden-code-block:: ruby

     def serialized_properties=(serialize_hash)
       @serialized_property_keys = nil
       @serialize = serialize_hash.clone
     end



.. _`Neo4j/Shared/SerializedProperties/ClassMethods#serialized_properties_keys`:

**#serialized_properties_keys**
  

  .. hidden-code-block:: ruby

     def serialized_properties_keys
       @serialized_property_keys ||= serialized_properties.keys
     end





