Dependent
=========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   Dependent/AssociationMethods

   Dependent/QueryProxyMethods




Constants
---------





Files
-----



  * `lib/neo4j/active_node/dependent.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/dependent.rb#L3>`_

  * `lib/neo4j/active_node/dependent/association_methods.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/dependent/association_methods.rb#L3>`_

  * `lib/neo4j/active_node/dependent/query_proxy_methods.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/dependent/query_proxy_methods.rb#L3>`_





Methods
-------



.. _`Neo4j/ActiveNode/Dependent#called_by=`:

**#called_by=**
  Sets the attribute called_by

  .. code-block:: ruby

     def called_by=(value)
       @called_by = value
     end



.. _`Neo4j/ActiveNode/Dependent#dependent_children`:

**#dependent_children**
  

  .. code-block:: ruby

     def dependent_children
       @dependent_children ||= []
     end





