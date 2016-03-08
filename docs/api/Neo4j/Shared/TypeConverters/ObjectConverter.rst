ObjectConverter
===============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/type_converters.rb:296 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/type_converters.rb#L296>`_





Methods
-------



.. _`Neo4j/Shared/TypeConverters/ObjectConverter.convert_type`:

**.convert_type**
  

  .. code-block:: ruby

     def convert_type
       Object
     end



.. _`Neo4j/Shared/TypeConverters/ObjectConverter.converted?`:

**.converted?**
  

  .. code-block:: ruby

     def converted?(value)
       value.is_a?(db_type)
     end



.. _`Neo4j/Shared/TypeConverters/ObjectConverter.to_ruby`:

**.to_ruby**
  

  .. code-block:: ruby

     def to_ruby(value)
       value
     end





