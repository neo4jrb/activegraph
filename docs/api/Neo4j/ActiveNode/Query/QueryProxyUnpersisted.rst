QueryProxyUnpersisted
=====================






.. toctree::
   :maxdepth: 3
   :titlesonly:


   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/query/query_proxy_unpersisted.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_unpersisted.rb#L4>`_





Methods
-------



.. _`Neo4j/ActiveNode/Query/QueryProxyUnpersisted#defer_create`:

**#defer_create**
  

  .. code-block:: ruby

     def defer_create(other_node)
       @start_object.pending_associations << @association.name
     
       @start_object.association_proxy(@association.name).add_to_cache(other_node)
     end





