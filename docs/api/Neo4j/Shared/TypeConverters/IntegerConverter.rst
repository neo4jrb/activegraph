IntegerConverter
================






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/type_converters.rb:22 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/type_converters.rb#L22>`_





Methods
-------



.. _`Neo4j/Shared/TypeConverters/IntegerConverter.convert_type`:

**.convert_type**
  

  .. code-block:: ruby

     def convert_type
       Integer
     end



.. _`Neo4j/Shared/TypeConverters/IntegerConverter.converted?`:

**.converted?**
  

  .. code-block:: ruby

     def converted?(value)
       value.is_a?(db_type)
     end



.. _`Neo4j/Shared/TypeConverters/IntegerConverter.db_type`:

**.db_type**
  

  .. code-block:: ruby

     def db_type
       Integer
     end



.. _`Neo4j/Shared/TypeConverters/IntegerConverter.to_db`:

**.to_db**
  

  .. code-block:: ruby

     def to_db(value)
       value.to_i
     end



.. _`Neo4j/Shared/TypeConverters/IntegerConverter.to_ruby`:

**.to_ruby**
  

  .. code-block:: ruby

     def to_db(value)
       value.to_i
     end





