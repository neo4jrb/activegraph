BooleanConverter
================






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   




Constants
---------



  * FALSE_VALUES



Files
-----



  * `lib/neo4j/shared/type_converters.rb:98 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/type_converters.rb#L98>`_





Methods
-------



.. _`Neo4j/Shared/TypeConverters/BooleanConverter.convert_type`:

**.convert_type**
  

  .. code-block:: ruby

     def db_type
       Neo4j::Shared::Boolean
     end



.. _`Neo4j/Shared/TypeConverters/BooleanConverter.converted?`:

**.converted?**
  

  .. code-block:: ruby

     def converted?(value)
       converted_values.include?(value)
     end



.. _`Neo4j/Shared/TypeConverters/BooleanConverter.converted_values`:

**.converted_values**
  

  .. code-block:: ruby

     def converted_values
       [true, false]
     end



.. _`Neo4j/Shared/TypeConverters/BooleanConverter.db_type`:

**.db_type**
  

  .. code-block:: ruby

     def db_type
       Neo4j::Shared::Boolean
     end



.. _`Neo4j/Shared/TypeConverters/BooleanConverter.to_db`:

**.to_db**
  

  .. code-block:: ruby

     def to_db(value)
       return false if FALSE_VALUES.include?(value)
       case value
       when TrueClass, FalseClass
         value
       when Numeric, /^\-?[0-9]/
         !value.to_f.zero?
       else
         value.present?
       end
     end



.. _`Neo4j/Shared/TypeConverters/BooleanConverter.to_ruby`:

**.to_ruby**
  

  .. code-block:: ruby

     def to_db(value)
       return false if FALSE_VALUES.include?(value)
       case value
       when TrueClass, FalseClass
         value
       when Numeric, /^\-?[0-9]/
         !value.to_f.zero?
       else
         value.present?
       end
     end





