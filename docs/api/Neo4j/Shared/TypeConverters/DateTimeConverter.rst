DateTimeConverter
=================




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   




Constants
---------



  * DATETIME_FORMAT



Files
-----



  * `lib/neo4j/shared/type_converters.rb:21 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/type_converters.rb#L21>`_





Methods
-------


**#convert_type**
  

  .. hidden-code-block:: ruby

     def convert_type
       DateTime
     end


**#to_db**
  Converts the given DateTime (UTC) value to an Integer.
  DateTime values are automatically converted to UTC.

  .. hidden-code-block:: ruby

     def to_db(value)
       value = value.new_offset(0) if value.respond_to?(:new_offset)
     
       args = [value.year, value.month, value.day]
       args += (value.class == Date ? [0, 0, 0] : [value.hour, value.min, value.sec])
     
       Time.utc(*args).to_i
     end


**#to_ruby**
  

  .. hidden-code-block:: ruby

     def to_ruby(value)
       t = case value
           when Integer
             Time.at(value).utc
           when String
             DateTime.strptime(value, DATETIME_FORMAT)
           else
             fail ArgumentError, "Invalid value type for DateType property: #{value.inspect}"
           end
     
       DateTime.civil(t.year, t.month, t.day, t.hour, t.min, t.sec)
     end





