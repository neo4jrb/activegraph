QueryProxyEnumerable
====================



Methods related to returning nodes and rels from QueryProxy


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/query/query_proxy_enumerable.rb:5 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_enumerable.rb#L5>`_





Methods
-------



.. _`Neo4j/ActiveNode/Query/QueryProxyEnumerable#==`:

**#==**
  Does exactly what you would hope. Without it, comparing `bobby.lessons == sandy.lessons` would evaluate to false because it
  would be comparing the QueryProxy objects, not the lessons themselves.

  .. code-block:: ruby

     def ==(other)
       self.to_a == other
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyEnumerable#each`:

**#each**
  Just like every other <tt>each</tt> but it allows for optional params to support the versions that also return relationships.
  The <tt>node</tt> and <tt>rel</tt> params are typically used by those other methods but there's nothing stopping you from
  using `your_node.each(true, true)` instead of `your_node.each_with_rel`.

  .. code-block:: ruby

     def each(node = true, rel = nil, &block)
       result(node, rel).each(&block)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyEnumerable#each_rel`:

**#each_rel**
  When called at the end of a QueryProxy chain, it will return the resultant relationship objects intead of nodes.
  For example, to return the relationship between a given student and their lessons:
  
  .. code-block:: ruby
  
    student.lessons.each_rel do |rel|

  .. code-block:: ruby

     def each_rel(&block)
       block_given? ? each(false, true, &block) : to_enum(:each, false, true)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyEnumerable#each_with_rel`:

**#each_with_rel**
  When called at the end of a QueryProxy chain, it will return the nodes and relationships of the last link.
  For example, to return a lesson and each relationship to a given student:
  
  .. code-block:: ruby
  
    student.lessons.each_with_rel do |lesson, rel|

  .. code-block:: ruby

     def each_with_rel(&block)
       block_given? ? each(true, true, &block) : to_enum(:each, true, true)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyEnumerable#fetch_result_cache`:

**#fetch_result_cache**
  

  .. code-block:: ruby

     def fetch_result_cache
       @result_cache ||= yield
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyEnumerable#pluck`:

**#pluck**
  For getting variables which have been defined as part of the association chain

  .. code-block:: ruby

     def pluck(*args)
       transformable_attributes = (model ? model.attribute_names : []) + %w(uuid neo_id)
       arg_list = args.map do |arg|
         if transformable_attributes.include?(arg.to_s)
           {identity => arg}
         else
           arg
         end
       end
     
       self.query.pluck(*arg_list)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyEnumerable#result`:

**#result**
  

  .. code-block:: ruby

     def result(node = true, rel = nil)
       @result_cache ||= {}
       return result_cache_for(node, rel) if result_cache?(node, rel)
     
       pluck_vars = []
       pluck_vars << identity if node
       pluck_vars << @rel_var if rel
     
       result = pluck(*pluck_vars)
     
       result.each do |object|
         object.instance_variable_set('@source_query_proxy', self)
         object.instance_variable_set('@source_proxy_result_cache', result)
       end
     
       @result_cache[[node, rel]] ||= result
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyEnumerable#result_cache?`:

**#result_cache?**
  

  .. code-block:: ruby

     def result_cache?(node = true, rel = nil)
       !!result_cache_for(node, rel)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyEnumerable#result_cache_for`:

**#result_cache_for**
  

  .. code-block:: ruby

     def result_cache_for(node = true, rel = nil)
       (@result_cache || {})[[node, rel]]
     end





