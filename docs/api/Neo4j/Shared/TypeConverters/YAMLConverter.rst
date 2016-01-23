YAMLConverter
=============



Converts hash to/from YAML


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/type_converters.rb:227 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/type_converters.rb#L227>`_





Methods
-------



.. _`Neo4j/Shared/TypeConverters/YAMLConverter.convert_type`:

**.convert_type**
  

  .. code-block:: ruby

     def convert_type
       Hash
     end



.. _`Neo4j/Shared/TypeConverters/YAMLConverter.converted?`:

**.converted?**
  

  .. code-block:: ruby

     def converted?(value)
       value.is_a?(db_type)
     end



.. _`Neo4j/Shared/TypeConverters/YAMLConverter.db_type`:

**.db_type**
  

  .. code-block:: ruby

     def db_type
       String
     end



.. _`Neo4j/Shared/TypeConverters/YAMLConverter.to_db`:

**.to_db**
  

  .. code-block:: ruby

     def to_db(value)
       Psych.dump(value)
     end



.. _`Neo4j/Shared/TypeConverters/YAMLConverter.to_ruby`:

**.to_ruby**
  

  .. code-block:: ruby

     def to_ruby(value)
       Psych.load(value)
     end





