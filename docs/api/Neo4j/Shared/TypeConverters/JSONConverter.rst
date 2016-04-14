JSONConverter
=============



Converts hash to/from JSON


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/type_converters.rb:248 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/type_converters.rb#L248>`_





Methods
-------



.. _`Neo4j/Shared/TypeConverters/JSONConverter.convert_type`:

**.convert_type**
  

  .. code-block:: ruby

     def convert_type
       JSON
     end



.. _`Neo4j/Shared/TypeConverters/JSONConverter.converted?`:

**.converted?**
  

  .. code-block:: ruby

     def converted?(value)
       value.is_a?(db_type)
     end



.. _`Neo4j/Shared/TypeConverters/JSONConverter.db_type`:

**.db_type**
  

  .. code-block:: ruby

     def db_type
       String
     end



.. _`Neo4j/Shared/TypeConverters/JSONConverter.to_db`:

**.to_db**
  

  .. code-block:: ruby

     def to_db(value)
       value.to_json
     end



.. _`Neo4j/Shared/TypeConverters/JSONConverter.to_ruby`:

**.to_ruby**
  

  .. code-block:: ruby

     def to_ruby(value)
       JSON.parse(value, quirks_mode: true)
     end





