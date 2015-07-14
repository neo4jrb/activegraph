AssociationProxy
================



Return this object from associations
It uses a QueryProxy to get results
But also caches results and can have results cached on it


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------



  * QUERY_PROXY_METHODS

  * CACHED_RESULT_METHODS



Files
-----



  * `lib/neo4j/active_node/has_n.rb:10 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/has_n.rb#L10>`_





Methods
-------



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#cache_query_proxy_result`:

**#cache_query_proxy_result**
  

  .. hidden-code-block:: ruby

     def cache_query_proxy_result
       @query_proxy.to_a.tap do |result|
         result.each do |object|
           object.instance_variable_set('@association_proxy', self)
         end
         cache_result(result)
       end
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#cache_result`:

**#cache_result**
  

  .. hidden-code-block:: ruby

     def cache_result(result)
       @cached_result = result
       @enumerable = (@cached_result || @query_proxy)
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#cached?`:

**#cached?**
  

  .. hidden-code-block:: ruby

     def cached?
       !!@cached_result
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#clear_cache_result`:

**#clear_cache_result**
  

  .. hidden-code-block:: ruby

     def clear_cache_result
       cache_result(nil)
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#each`:

**#each**
  

  .. hidden-code-block:: ruby

     def each(&block)
       result.each(&block)
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#initialize`:

**#initialize**
  

  .. hidden-code-block:: ruby

     def initialize(query_proxy, cached_result = nil)
       @query_proxy = query_proxy
       cache_result(cached_result)
     
       # Represents the thing which can be enumerated
       # default to @query_proxy, but will be set to
       # @cached_result if that is set
       @enumerable = @query_proxy
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#inspect`:

**#inspect**
  States:
  Default

  .. hidden-code-block:: ruby

     def inspect
       if @cached_result
         @cached_result.inspect
       else
         "<AssociationProxy @query_proxy=#{@query_proxy.inspect}>"
       end
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#method_missing`:

**#method_missing**
  

  .. hidden-code-block:: ruby

     def method_missing(method_name, *args, &block)
       target = target_for_missing_method(method_name)
     
       cache_query_proxy_result if !cached? && !target.is_a?(Neo4j::ActiveNode::Query::QueryProxy)
     
       clear_cache_result if target.is_a?(Neo4j::ActiveNode::Query::QueryProxy)
     
       return if target.nil?
     
       target.public_send(method_name, *args, &block)
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#result`:

**#result**
  

  .. hidden-code-block:: ruby

     def result
       return @cached_result if @cached_result
     
       cache_query_proxy_result
     
       @cached_result
     end





