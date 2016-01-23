TimeConverter
=============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/type_converters.rb:194 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/type_converters.rb#L194>`_





Methods
-------



.. _`Neo4j/Shared/TypeConverters/TimeConverter.convert_type`:

**.convert_type**
  

  .. code-block:: ruby

     def convert_type
       Time
     end



.. _`Neo4j/Shared/TypeConverters/TimeConverter.converted?`:

**.converted?**
  

  .. code-block:: ruby

     def converted?(value)
       value.is_a?(db_type)
     end



.. _`Neo4j/Shared/TypeConverters/TimeConverter.db_type`:

**.db_type**
  

  .. code-block:: ruby

     def db_type
       Integer
     end



.. _`Neo4j/Shared/TypeConverters/TimeConverter.primitive_type`:

**.primitive_type**
  ActiveAttr, which assists with property management, does not recognize Time as a valid type. We tell it to interpret it as
  Integer, as it will be when saved to the database.

  .. code-block:: ruby

     def primitive_type
       Integer
     end



.. _`Neo4j/Shared/TypeConverters/TimeConverter.to_db`:

**.to_db**
  Converts the given DateTime (UTC) value to an Integer.
  Only utc times are supported !

  .. code-block:: ruby

     def to_db(value)
       if value.class == Date
         Time.utc(value.year, value.month, value.day, 0, 0, 0).to_i
       else
         value.utc.to_i
       end
     end



.. _`Neo4j/Shared/TypeConverters/TimeConverter.to_ruby`:

**.to_ruby**
  

  .. code-block:: ruby

     def to_ruby(value)
       Time.at(value).utc
     end





