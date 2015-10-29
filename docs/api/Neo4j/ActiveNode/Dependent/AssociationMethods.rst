AssociationMethods
==================






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/dependent/association_methods.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/dependent/association_methods.rb#L4>`_





Methods
-------



.. _`Neo4j/ActiveNode/Dependent/AssociationMethods#add_destroy_callbacks`:

**#add_destroy_callbacks**
  

  .. code-block:: ruby

     def add_destroy_callbacks(model)
       return if dependent.nil?
     
       model.before_destroy(&method("dependent_#{dependent}_callback"))
     rescue NameError
       raise "Unknown dependent option #{dependent}"
     end



.. _`Neo4j/ActiveNode/Dependent/AssociationMethods#validate_dependent`:

**#validate_dependent**
  

  .. code-block:: ruby

     def validate_dependent(value)
       fail ArgumentError, "Invalid dependent value: #{value.inspect}" if not valid_dependent_value?(value)
     end





