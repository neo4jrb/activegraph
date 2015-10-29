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

     def defer_create(other_nodes, _properties, operator)
       key = [@association.name, [nil, nil, nil]].hash
       @start_object.pending_associations[key] = [@association.name, operator]
       if @start_object.association_proxy_cache[key]
         @start_object.association_proxy_cache[key] << other_nodes
       else
         @start_object.association_proxy_cache[key] = [other_nodes]
       end
     end





