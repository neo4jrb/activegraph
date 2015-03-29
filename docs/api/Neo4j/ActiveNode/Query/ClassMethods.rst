ClassMethods
============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   




Constants
---------





Files
-----



  * lib/neo4j/active_node/query.rb:35





Methods
-------


**#as**
  Start a new QueryProxy with the starting identifier set to the given argument.
  This method does not exist within QueryProxy, it can only be called at the class level to create a new QP object.
  To set an identifier within a QueryProxy chain, give it as the first argument to a chained association.

  .. hidden-code-block:: ruby

     def as(node_var)
       query_proxy(node: node_var)
     end


**#query_as**
  Returns a Query object with all nodes for the model matched as the specified variable name

  .. hidden-code-block:: ruby

     def query_as(var)
       query_proxy.query_as(var)
     end


**#query_proxy**
  

  .. hidden-code-block:: ruby

     def query_proxy(options = {})
       Neo4j::ActiveNode::Query::QueryProxy.new(self, nil, options)
     end





