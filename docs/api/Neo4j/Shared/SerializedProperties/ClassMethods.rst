ClassMethods
============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   




Constants
---------





Files
-----



  * lib/neo4j/shared/serialized_properties.rb:18





Methods
-------


**#serialize**
  

  .. hidden-code-block:: ruby

     def serialize(name, coder = JSON)
       @serialize ||= {}
       @serialize[name] = coder
     end


**#serialized_properties**
  

  .. hidden-code-block:: ruby

     def serialized_properties
       @serialize || {}
     end


**#serialized_properties=**
  

  .. hidden-code-block:: ruby

     def serialized_properties=(serialize_hash)
       @serialize = serialize_hash.clone
     end





