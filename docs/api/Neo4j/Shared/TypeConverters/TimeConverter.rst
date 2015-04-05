TimeConverter
=============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/type_converters.rb:54 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/type_converters.rb#L54>`_





Methods
-------



.. _`Neo4j/Shared/TypeConverters/TimeConverter.convert_type`:

**.convert_type**
  

  .. hidden-code-block:: ruby

     def convert_type
       Time
     end



.. _`Neo4j/Shared/TypeConverters/TimeConverter.to_db`:

**.to_db**
  Converts the given DateTime (UTC) value to an Integer.
  Only utc times are supported !

  .. hidden-code-block:: ruby

     def to_db(value)
       if value.class == Date
         Time.utc(value.year, value.month, value.day, 0, 0, 0).to_i
       else
         value.utc.to_i
       end
     end



.. _`Neo4j/Shared/TypeConverters/TimeConverter.to_ruby`:

**.to_ruby**
  

  .. hidden-code-block:: ruby

     def to_ruby(value)
       Time.at(value).utc
     end





