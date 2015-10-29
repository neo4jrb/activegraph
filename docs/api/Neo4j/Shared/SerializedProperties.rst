SerializedProperties
====================



This module adds the `serialize` class method. It lets you store hashes and arrays in Neo4j properties.
Be aware that you won't be able to search within serialized properties and stuff use indexes. If you do a regex search for portion of a string
property, the search happens in Cypher and you may take a performance hit.

See type_converters.rb for the serialization process.


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   SerializedProperties/ClassMethods




Constants
---------





Files
-----



  * `lib/neo4j/shared/serialized_properties.rb:7 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/serialized_properties.rb#L7>`_





Methods
-------



.. _`Neo4j/Shared/SerializedProperties#serializable_hash`:

**#serializable_hash**
  

  .. code-block:: ruby

     def serializable_hash(*args)
       super.merge(id: id)
     end



.. _`Neo4j/Shared/SerializedProperties#serialized_properties`:

**#serialized_properties**
  

  .. code-block:: ruby

     def serialized_properties
       self.class.serialized_properties
     end





