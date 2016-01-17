Marshal
=======






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/marshal.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/marshal.rb#L3>`_





Methods
-------



.. _`Neo4j/Shared/Marshal#marshal_dump`:

**#marshal_dump**
  

  .. code-block:: ruby

     def marshal_dump
       marshal_instance_variables.map(&method(:instance_variable_get))
     end



.. _`Neo4j/Shared/Marshal#marshal_load`:

**#marshal_load**
  

  .. code-block:: ruby

     def marshal_load(array)
       marshal_instance_variables.zip(array).each do |var, value|
         instance_variable_set(var, value)
       end
     end





