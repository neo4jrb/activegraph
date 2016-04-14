FloatConverter
==============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/type_converters.rb:40 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/type_converters.rb#L40>`_





Methods
-------



.. _`Neo4j/Shared/TypeConverters/FloatConverter.convert_type`:

**.convert_type**
  

  .. code-block:: ruby

     def convert_type
       Float
     end



.. _`Neo4j/Shared/TypeConverters/FloatConverter.converted?`:

**.converted?**
  

  .. code-block:: ruby

     def converted?(value)
       value.is_a?(db_type)
     end



.. _`Neo4j/Shared/TypeConverters/FloatConverter.db_type`:

**.db_type**
  

  .. code-block:: ruby

     def db_type
       Float
     end



.. _`Neo4j/Shared/TypeConverters/FloatConverter.to_db`:

**.to_db**
  

  .. code-block:: ruby

     def to_db(value)
       value.to_f
     end



.. _`Neo4j/Shared/TypeConverters/FloatConverter.to_ruby`:

**.to_ruby**
  

  .. code-block:: ruby

     def to_db(value)
       value.to_f
     end





