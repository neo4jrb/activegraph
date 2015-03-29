QueryProxyFindInBatches
=======================




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   




Constants
---------





Files
-----



  * lib/neo4j/active_node/query/query_proxy_find_in_batches.rb:4





Methods
-------


**#find_each**
  

  .. hidden-code-block:: ruby

     def find_each(options = {})
       query.return(identity).find_each(identity, @model.primary_key, options) do |result|
         yield result
       end
     end


**#find_in_batches**
  

  .. hidden-code-block:: ruby

     def find_in_batches(options = {})
       query.return(identity).find_in_batches(identity, @model.primary_key, options) do |batch|
         yield batch
       end
     end





