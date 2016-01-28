DateTimeConverter
=================



Converts DateTime objects to and from Java long types. Must be timezone UTC.


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   




Constants
---------



  * DATETIME_FORMAT



Files
-----



  * `lib/neo4j/shared/type_converters.rb:154 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/type_converters.rb#L154>`_





Methods
-------



.. _`Neo4j/Shared/TypeConverters/DateTimeConverter.convert_type`:

**.convert_type**
  

  .. code-block:: ruby

     def convert_type
       DateTime
     end



.. _`Neo4j/Shared/TypeConverters/DateTimeConverter.converted?`:

**.converted?**
  

  .. code-block:: ruby

     def converted?(value)
       value.is_a?(db_type)
     end



.. _`Neo4j/Shared/TypeConverters/DateTimeConverter.db_type`:

**.db_type**
  

  .. code-block:: ruby

     def db_type
       Integer
     end



.. _`Neo4j/Shared/TypeConverters/DateTimeConverter.to_db`:

**.to_db**
  Converts the given DateTime (UTC) value to an Integer.
  DateTime values are automatically converted to UTC.

  .. code-block:: ruby

     def to_db(value)
       value = value.new_offset(0) if value.respond_to?(:new_offset)
     
       args = [value.year, value.month, value.day]
       args += (value.class == Date ? [0, 0, 0] : [value.hour, value.min, value.sec])
     
       Time.utc(*args).to_i
     end



.. _`Neo4j/Shared/TypeConverters/DateTimeConverter.to_ruby`:

**.to_ruby**
  

  .. code-block:: ruby

     def to_ruby(value)
       return value if value.is_a?(DateTime)
       t = case value
           when Time
             return value.to_datetime.utc
           when Integer
             Time.at(value).utc
           when String
             DateTime.strptime(value, DATETIME_FORMAT)
           else
             fail ArgumentError, "Invalid value type for DateType property: #{value.inspect}"
           end
     
       DateTime.civil(t.year, t.month, t.day, t.hour, t.min, t.sec)
     end





