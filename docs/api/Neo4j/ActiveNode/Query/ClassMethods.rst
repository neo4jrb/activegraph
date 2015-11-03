ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/query.rb:35 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query.rb#L35>`_





Methods
-------



.. _`Neo4j/ActiveNode/Query/ClassMethods#as`:

**#as**
  Start a new QueryProxy with the starting identifier set to the given argument.
  This method does not exist within QueryProxy, it can only be called at the class level to create a new QP object.
  To set an identifier within a QueryProxy chain, give it as the first argument to a chained association.

  .. code-block:: ruby

     def as(node_var)
       query_proxy(node: node_var, context: self.name)
     end



.. _`Neo4j/ActiveNode/Query/ClassMethods#query_as`:

**#query_as**
  Returns a Query object with all nodes for the model matched as the specified variable name
  
  an early Cypher match has already filtered results) where including labels will degrade performance.

  .. code-block:: ruby

     def query_as(var, with_labels = true)
       query_proxy.query_as(var, with_labels)
     end



.. _`Neo4j/ActiveNode/Query/ClassMethods#query_proxy`:

**#query_proxy**
  

  .. code-block:: ruby

     def query_proxy(options = {})
       Neo4j::ActiveNode::Query::QueryProxy.new(self, nil, options)
     end





