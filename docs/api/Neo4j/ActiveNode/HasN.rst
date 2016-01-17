HasN
====






.. toctree::
   :maxdepth: 3
   :titlesonly:


   HasN/NonPersistedNodeError

   HasN/AssociationProxy

   

   

   

   

   

   

   

   HasN/ClassMethods

   HasN/Association

   HasN/AssociationCypherMethods




Constants
---------





Files
-----



  * `lib/neo4j/active_node/has_n.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/has_n.rb#L2>`_

  * `lib/neo4j/active_node/has_n/association.rb:6 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/has_n/association.rb#L6>`_

  * `lib/neo4j/active_node/has_n/association/rel_factory.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/has_n/association/rel_factory.rb#L1>`_

  * `lib/neo4j/active_node/has_n/association_cypher_methods.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/has_n/association_cypher_methods.rb#L3>`_





Methods
-------



.. _`Neo4j/ActiveNode/HasN#association_proxy`:

**#association_proxy**
  

  .. code-block:: ruby

     def association_proxy(name, options = {})
       name = name.to_sym
       hash = association_proxy_hash(name, options)
       association_proxy_cache_fetch(hash) do
         if result_cache = self.instance_variable_get('@source_proxy_result_cache')
           result_by_previous_id = previous_proxy_results_by_previous_id(result_cache, name)
     
           result_cache.inject(nil) do |proxy_to_return, object|
             proxy = fresh_association_proxy(name, options.merge(start_object: object), result_by_previous_id[object.neo_id])
     
             object.association_proxy_cache[hash] = proxy
     
             (self == object ? proxy : proxy_to_return)
           end
         else
           fresh_association_proxy(name, options)
         end
       end
     end



.. _`Neo4j/ActiveNode/HasN#association_proxy_cache`:

**#association_proxy_cache**
  Returns the current AssociationProxy cache for the association cache. It is in the format
  { :association_name => AssociationProxy}
  This is so that we
  * don't need to re-build the QueryProxy objects
  * also because the QueryProxy object caches it's results
  * so we don't need to query again
  * so that we can cache results from association calls or eager loading

  .. code-block:: ruby

     def association_proxy_cache
       @association_proxy_cache ||= {}
     end



.. _`Neo4j/ActiveNode/HasN#association_proxy_cache_fetch`:

**#association_proxy_cache_fetch**
  

  .. code-block:: ruby

     def association_proxy_cache_fetch(key)
       association_proxy_cache.fetch(key) do
         value = yield
         association_proxy_cache[key] = value
       end
     end



.. _`Neo4j/ActiveNode/HasN#association_proxy_hash`:

**#association_proxy_hash**
  

  .. code-block:: ruby

     def association_proxy_hash(name, options = {})
       [name.to_sym, options.values_at(:node, :rel, :labels, :rel_length)].hash
     end



.. _`Neo4j/ActiveNode/HasN#association_query_proxy`:

**#association_query_proxy**
  

  .. code-block:: ruby

     def association_query_proxy(name, options = {})
       self.class.send(:association_query_proxy, name, {start_object: self}.merge!(options))
     end





