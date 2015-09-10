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
  

  .. code-block:: ruby

     def each(node = true, rel = nil, &block)
       return super if with_associations_spec.size.zero?
     
       query_from_association_spec.pluck(identity, with_associations_return_clause).map do |record, eager_data|
         eager_data.each_with_index do |eager_records, index|
           record.association_proxy(with_associations_spec[index]).cache_result(eager_records)
         end
     
         block.call(record)
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyEagerLoading#with_associations`:

**#with_associations**
  

  .. code-block:: ruby

     def with_associations(*spec)
       invalid_association_names = spec.reject do |association_name|
         model.associations[association_name]
       end
     
       if invalid_association_names.size > 0
         fail "Invalid associations: #{invalid_association_names.join(', ')}"
       end
     
       new_link.tap do |new_query_proxy|
         new_spec = new_query_proxy.with_associations_spec + spec
         new_query_proxy.with_associations_spec.replace(new_spec)
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyEagerLoading#with_associations_return_clause`:

**#with_associations_return_clause**
  

  .. code-block:: ruby

     def with_associations_return_clause
       '[' + with_associations_spec.map { |n| "collect(#{n})" }.join(',') + ']'
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyEagerLoading#with_associations_spec`:

**#with_associations_spec**
  

  .. code-block:: ruby

     def with_associations_spec
       @with_associations_spec ||= []
     end





