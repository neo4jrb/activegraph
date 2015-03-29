SerializedProperties
====================




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   SerializedProperties/ClassMethods




Constants
---------





Files
-----



  * lib/neo4j/shared/serialized_properties.rb:7





Methods
-------


**#serializable_hash**
  

  .. hidden-code-block:: ruby

     def serializable_hash(*args)
       super.merge(id: id)
     end


**#serialized_properties**
  

  .. hidden-code-block:: ruby

     def serialized_properties
       self.class.serialized_properties
     end





