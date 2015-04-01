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


.. _ClassMethods_serialize:

**#serialize**
  

  .. hidden-code-block:: ruby

     def serialize(name, coder = JSON)
       @serialize ||= {}
       @serialize[name] = coder
     end


.. _ClassMethods_serialized_properties:

**#serialized_properties**
  

  .. hidden-code-block:: ruby

     def serialized_properties
       @serialize || {}
     end


.. _ClassMethods_serialized_properties=:

**#serialized_properties=**
  

  .. hidden-code-block:: ruby

     def serialized_properties=(serialize_hash)
       @serialize = serialize_hash.clone
     end





