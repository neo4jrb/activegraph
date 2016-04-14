BigDecimalConverter
===================






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/type_converters.rb:57 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/type_converters.rb#L57>`_





Methods
-------



.. _`Neo4j/Shared/TypeConverters/BigDecimalConverter.convert_type`:

**.convert_type**
  

  .. code-block:: ruby

     def convert_type
       BigDecimal
     end



.. _`Neo4j/Shared/TypeConverters/BigDecimalConverter.converted?`:

**.converted?**
  

  .. code-block:: ruby

     def converted?(value)
       value.is_a?(db_type)
     end



.. _`Neo4j/Shared/TypeConverters/BigDecimalConverter.db_type`:

**.db_type**
  

  .. code-block:: ruby

     def db_type
       BigDecimal
     end



.. _`Neo4j/Shared/TypeConverters/BigDecimalConverter.to_db`:

**.to_db**
  

  .. code-block:: ruby

     def to_db(value)
       case value
       when Rational
         value.to_f.to_d
       when respond_to?(:to_d)
         value.to_d
       else
         BigDecimal.new(value.to_s)
       end
     end



.. _`Neo4j/Shared/TypeConverters/BigDecimalConverter.to_ruby`:

**.to_ruby**
  

  .. code-block:: ruby

     def to_db(value)
       case value
       when Rational
         value.to_f.to_d
       when respond_to?(:to_d)
         value.to_d
       else
         BigDecimal.new(value.to_s)
       end
     end





