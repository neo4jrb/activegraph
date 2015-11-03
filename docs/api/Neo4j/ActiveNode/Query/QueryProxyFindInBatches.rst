QueryProxyFindInBatches
=======================






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/query/query_proxy_find_in_batches.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_find_in_batches.rb#L4>`_





Methods
-------



.. _`Neo4j/ActiveNode/Query/QueryProxyFindInBatches#find_each`:

**#find_each**
  

  .. code-block:: ruby

     def find_each(options = {})
       query.return(identity).find_each(identity, @model.primary_key, options) do |result|
         yield result.send(identity)
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyFindInBatches#find_in_batches`:

**#find_in_batches**
  

  .. code-block:: ruby

     def find_in_batches(options = {})
       query.return(identity).find_in_batches(identity, @model.primary_key, options) do |batch|
         yield batch.map(&:identity)
       end
     end





