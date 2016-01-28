DateConverter
=============



Converts Date objects to Java long types. Must be timezone UTC.


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/type_converters.rb:133 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/type_converters.rb#L133>`_





Methods
-------



.. _`Neo4j/Shared/TypeConverters/DateConverter.convert_type`:

**.convert_type**
  

  .. code-block:: ruby

     def convert_type
       Date
     end



.. _`Neo4j/Shared/TypeConverters/DateConverter.converted?`:

**.converted?**
  

  .. code-block:: ruby

     def converted?(value)
       value.is_a?(db_type)
     end



.. _`Neo4j/Shared/TypeConverters/DateConverter.db_type`:

**.db_type**
  

  .. code-block:: ruby

     def db_type
       Integer
     end



.. _`Neo4j/Shared/TypeConverters/DateConverter.to_db`:

**.to_db**
  

  .. code-block:: ruby

     def to_db(value)
       Time.utc(value.year, value.month, value.day).to_i
     end



.. _`Neo4j/Shared/TypeConverters/DateConverter.to_ruby`:

**.to_ruby**
  

  .. code-block:: ruby

     def to_ruby(value)
       value.respond_to?(:to_date) ? value.to_date : Time.at(value).utc.to_date
     end





