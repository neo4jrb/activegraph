EnumConverter
=============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/type_converters.rb:268 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/type_converters.rb#L268>`_





Methods
-------



.. _`Neo4j/Shared/TypeConverters/EnumConverter#call`:

**#call**
  

  .. code-block:: ruby

     def to_ruby(value)
       @enum_keys.key(value) unless value.nil?
     end



.. _`Neo4j/Shared/TypeConverters/EnumConverter#convert_type`:

**#convert_type**
  

  .. code-block:: ruby

     def convert_type
       Symbol
     end



.. _`Neo4j/Shared/TypeConverters/EnumConverter#converted?`:

**#converted?**
  

  .. code-block:: ruby

     def converted?(value)
       value.is_a?(db_type)
     end



.. _`Neo4j/Shared/TypeConverters/EnumConverter#db_type`:

**#db_type**
  

  .. code-block:: ruby

     def db_type
       Integer
     end



.. _`Neo4j/Shared/TypeConverters/EnumConverter#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(enum_keys)
       @enum_keys = enum_keys
     end



.. _`Neo4j/Shared/TypeConverters/EnumConverter#to_db`:

**#to_db**
  

  .. code-block:: ruby

     def to_db(value)
       @enum_keys[value.to_s.to_sym] || 0
     end



.. _`Neo4j/Shared/TypeConverters/EnumConverter#to_ruby`:

**#to_ruby**
  

  .. code-block:: ruby

     def to_ruby(value)
       @enum_keys.key(value) unless value.nil?
     end





