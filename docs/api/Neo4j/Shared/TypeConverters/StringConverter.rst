StringConverter
===============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/type_converters.rb:81 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/type_converters.rb#L81>`_





Methods
-------



.. _`Neo4j/Shared/TypeConverters/StringConverter.convert_type`:

**.convert_type**
  

  .. code-block:: ruby

     def convert_type
       String
     end



.. _`Neo4j/Shared/TypeConverters/StringConverter.converted?`:

**.converted?**
  

  .. code-block:: ruby

     def converted?(value)
       value.is_a?(db_type)
     end



.. _`Neo4j/Shared/TypeConverters/StringConverter.db_type`:

**.db_type**
  

  .. code-block:: ruby

     def db_type
       String
     end



.. _`Neo4j/Shared/TypeConverters/StringConverter.to_db`:

**.to_db**
  

  .. code-block:: ruby

     def to_db(value)
       value.to_s
     end



.. _`Neo4j/Shared/TypeConverters/StringConverter.to_ruby`:

**.to_ruby**
  

  .. code-block:: ruby

     def to_db(value)
       value.to_s
     end





