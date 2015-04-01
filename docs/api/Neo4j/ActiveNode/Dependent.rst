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


.. _Dependent_called_by=:

**#called_by=**
  Sets the attribute called_by

  .. hidden-code-block:: ruby

     def called_by=(value)
       @called_by = value
     end


.. _Dependent_dependent_children:

**#dependent_children**
  

  .. hidden-code-block:: ruby

     def dependent_children
       @dependent_children ||= []
     end





