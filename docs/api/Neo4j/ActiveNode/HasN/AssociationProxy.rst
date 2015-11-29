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



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#+`:

**#+**
  

  .. code-block:: ruby

     def +(other)
       self.to_a + other
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#==`:

**#==**
  

  .. code-block:: ruby

     def ==(other)
       self.to_a == other.to_a
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#add_to_cache`:

**#add_to_cache**
  

  .. code-block:: ruby

     def add_to_cache(object)
       @cached_result ||= []
       @cached_result << object
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#cache_query_proxy_result`:

**#cache_query_proxy_result**
  

  .. code-block:: ruby

     def cache_query_proxy_result
       @query_proxy.to_a.tap { |result| cache_result(result) }
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#cache_result`:

**#cache_result**
  

  .. code-block:: ruby

     def cache_result(result)
       @cached_result = result
       @enumerable = (@cached_result || @query_proxy)
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#cached?`:

**#cached?**
  

  .. code-block:: ruby

     def cached?
       !!@cached_result
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#clear_cache_result`:

**#clear_cache_result**
  

  .. code-block:: ruby

     def clear_cache_result
       cache_result(nil)
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#each`:

**#each**
  

  .. code-block:: ruby

     def each(&block)
       result_nodes.each(&block)
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(query_proxy, deferred_objects = [], cached_result = nil)
       @query_proxy = query_proxy
       @deferred_objects = deferred_objects
     
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

  .. code-block:: ruby

     def inspect
       if @cached_result
         result_nodes.inspect
       else
         "#<AssociationProxy @query_proxy=#{@query_proxy.inspect}>"
       end
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#method_missing`:

**#method_missing**
  

  .. code-block:: ruby

     def method_missing(method_name, *args, &block)
       target = target_for_missing_method(method_name)
       super if target.nil?
     
       cache_query_proxy_result if !cached? && !target.is_a?(Neo4j::ActiveNode::Query::QueryProxy)
       clear_cache_result if !QUERY_PROXY_METHODS.include?(method_name) && target.is_a?(Neo4j::ActiveNode::Query::QueryProxy)
     
       target.public_send(method_name, *args, &block)
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#replace_with`:

**#replace_with**
  

  .. code-block:: ruby

     def replace_with(*args)
       @cached_result = nil
     
       @query_proxy.public_send(:replace_with, *args)
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#result`:

**#result**
  

  .. code-block:: ruby

     def result
       (@deferred_objects || []) + result_without_deferred
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#result_ids`:

**#result_ids**
  

  .. code-block:: ruby

     def result_ids
       result.map do |object|
         object.is_a?(Neo4j::ActiveNode) ? object.id : object
       end
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#result_nodes`:

**#result_nodes**
  

  .. code-block:: ruby

     def result_nodes
       return result_objects if !@query_proxy.model
     
       result_objects.map do |object|
         object.is_a?(Neo4j::ActiveNode) ? object : @query_proxy.model.find(object)
       end
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#result_objects`:

**#result_objects**
  

  .. code-block:: ruby

     def result_objects
       @deferred_objects + result_without_deferred
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#result_without_deferred`:

**#result_without_deferred**
  

  .. code-block:: ruby

     def result_without_deferred
       cache_query_proxy_result if !@cached_result
     
       @cached_result
     end



.. _`Neo4j/ActiveNode/HasN/AssociationProxy#serializable_hash`:

**#serializable_hash**
  

  .. code-block:: ruby

     def serializable_hash(options = {})
       to_a.map { |record| record.serializable_hash(options) }
     end





