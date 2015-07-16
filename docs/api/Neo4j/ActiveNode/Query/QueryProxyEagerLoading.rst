QueryProxyEagerLoading
======================






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/query/query_proxy_eager_loading.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_eager_loading.rb#L4>`_





Methods
-------



.. _`Neo4j/ActiveNode/Query/QueryProxyEagerLoading#each`:

**#each**
  

  .. hidden-code-block:: ruby

     def each(node = true, rel = nil, &block)
       if @associations_spec.size > 0
         return_object_clause = '[' + @associations_spec.map { |n| "collect(#{n})" }.join(',') + ']'
         query_from_association_spec.pluck(identity, return_object_clause).map do |record, eager_data|
           eager_data.each_with_index do |eager_records, index|
             record.association_proxy(@associations_spec[index]).cache_result(eager_records)
           end
     
           block.call(record)
         end
       else
         super
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyEagerLoading#initialize`:

**#initialize**
  

  .. hidden-code-block:: ruby

     def initialize(model, association = nil, options = {})
       @associations_spec = []
     
       super
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyEagerLoading#with_associations`:

**#with_associations**
  

  .. hidden-code-block:: ruby

     def with_associations(*spec)
       new_link.tap do |new_query_proxy|
         new_spec = new_query_proxy.instance_variable_get('@associations_spec') + spec
         new_query_proxy.instance_variable_set('@associations_spec', new_spec)
       end
     end





