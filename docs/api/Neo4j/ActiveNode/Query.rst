Query
=====



Helper methods to return Neo4j::Core::Query objects.  A query object can be used to successively build a cypher query

   person.query_as(:n).match('n-[:friend]-o').return(o: :name) # Return the names of all the person's friends


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   Query/ClassMethods

   Query/QueryProxy

   Query/QueryProxyMethods

   Query/QueryProxyEnumerable

   Query/QueryProxyEagerLoading

   Query/QueryProxyFindInBatches

   Query/QueryProxyMethodsOfMassUpdating




Constants
---------





Files
-----



  * `lib/neo4j/active_node/query.rb:7 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query.rb#L7>`_

  * `lib/neo4j/active_node/query/query_proxy.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy.rb#L3>`_

  * `lib/neo4j/active_node/query/query_proxy_link.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_link.rb#L3>`_

  * `lib/neo4j/active_node/query/query_proxy_methods.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_methods.rb#L3>`_

  * `lib/neo4j/active_node/query/query_proxy_enumerable.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_enumerable.rb#L3>`_

  * `lib/neo4j/active_node/query/query_proxy_eager_loading.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_eager_loading.rb#L3>`_

  * `lib/neo4j/active_node/query/query_proxy_find_in_batches.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_find_in_batches.rb#L3>`_

  * `lib/neo4j/active_node/query/query_proxy_methods_of_mass_updating.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_methods_of_mass_updating.rb#L3>`_





Methods
-------



.. _`Neo4j/ActiveNode/Query#as`:

**#as**
  Starts a new QueryProxy with the starting identifier set to the given argument and QueryProxy source_object set to the node instance.
  This method does not exist within QueryProxy and can only be used to start a new chain.

  .. code-block:: ruby

     def as(node_var)
       self.class.query_proxy(node: node_var, source_object: self).match_to(self)
     end



.. _`Neo4j/ActiveNode/Query#query_as`:

**#query_as**
  Returns a Query object with the current node matched the specified variable name

  .. code-block:: ruby

     def query_as(node_var)
       self.class.query_as(node_var, false).where("ID(#{node_var})" => self.neo_id)
     end





