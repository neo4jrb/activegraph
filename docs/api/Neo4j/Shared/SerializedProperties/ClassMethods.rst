ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/serialized_properties.rb:19 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/serialized_properties.rb#L19>`_





Methods
-------



.. _`Neo4j/Shared/SerializedProperties/ClassMethods#inherit_serialized_properties`:

**#inherit_serialized_properties**
  

  .. code-block:: ruby

     def inherit_serialized_properties(other)
       other.serialized_properties = self.serialized_properties
     end



.. _`Neo4j/Shared/SerializedProperties/ClassMethods#inherited`:

**#inherited**
  

  .. code-block:: ruby

     def inherited(other)
       inherit_serialized_properties(other) if self.respond_to?(:serialized_properties)
       super
     end





