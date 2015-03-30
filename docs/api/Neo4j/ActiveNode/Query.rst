Query
=====




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   Query/ClassMethods

   Query/QueryProxy

   Query/QueryProxyMethods

   Query/QueryProxyEnumerable

   Query/QueryProxyFindInBatches




Constants
---------





Files
-----



  * `lib/neo4j/active_node/query.rb:7 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query.rb#L7>`_

  * `lib/neo4j/active_node/query/query_proxy.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy.rb#L3>`_

  * `lib/neo4j/active_node/query/query_proxy_link.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_link.rb#L3>`_

  * `lib/neo4j/active_node/query/query_proxy_methods.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_methods.rb#L3>`_

  * `lib/neo4j/active_node/query/query_proxy_enumerable.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_enumerable.rb#L3>`_

  * `lib/neo4j/active_node/query/query_proxy_find_in_batches.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_find_in_batches.rb#L3>`_





Methods
-------


**#as**
  Starts a new QueryProxy with the starting identifier set to the given argument and QueryProxy caller set to the node instance.
  This method does not exist within QueryProxy and can only be used to start a new chain.

  .. hidden-code-block:: ruby

     def as(node_var)
       self.class.query_proxy(node: node_var, caller: self).match_to(self)
     end


**#query_as**
  Returns a Query object with the current node matched the specified variable name

  .. hidden-code-block:: ruby

     def query_as(node_var)
       self.class.query_as(node_var).where("ID(#{node_var})" => self.neo_id)
     end





