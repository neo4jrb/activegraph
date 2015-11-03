GeneratedAttribute
==================



:nodoc:


.. toctree::
   :maxdepth: 3
   :titlesonly:


   




Constants
---------





Files
-----



  * `lib/rails/generators/neo4j_generator.rb:53 <https://github.com/neo4jrb/neo4j/blob/master/lib/rails/generators/neo4j_generator.rb#L53>`_





Methods
-------



.. _`Rails/Generators/GeneratedAttribute#type_class`:

**#type_class**
  

  .. code-block:: ruby

     def type_class
       case type.to_s.downcase
       when 'any' then 'any'
       when 'datetime' then 'DateTime'
       when 'date' then 'Date'
       when 'integer', 'number', 'fixnum' then 'Integer'
       when 'float' then 'Float'
       else
         'String'
       end
     end





