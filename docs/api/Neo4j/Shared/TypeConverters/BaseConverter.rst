BaseConverter
=============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   




Constants
---------





Files
-----



  * `lib/neo4j/shared/type_converters.rb:14 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/type_converters.rb#L14>`_





Methods
-------



.. _`Neo4j/Shared/TypeConverters/BaseConverter.converted?`:

**.converted?**
  

  .. code-block:: ruby

     def converted?(value)
       value.is_a?(db_type)
     end





