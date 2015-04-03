QueryProxyEnumerable
====================




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

  .. hidden-code-block:: ruby

     def ==(other)
       self.to_a == other
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyEnumerable#each`:

**#each**
  Just like every other <tt>each</tt> but it allows for optional params to support the versions that also return relationships.
  The <tt>node</tt> and <tt>rel</tt> params are typically used by those other methods but there's nothing stopping you from
  using `your_node.each(true, true)` instead of `your_node.each_with_rel`.

  .. hidden-code-block:: ruby

     def each(node = true, rel = nil, &_block)
       if node && rel
         enumerable_query(identity, rel_var).each { |returned_node, returned_rel| yield returned_node, returned_rel }
       else
         pluck_this = !rel ? identity : @rel_var
         enumerable_query(pluck_this).each { |returned_node| yield returned_node }
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyEnumerable#each_rel`:

**#each_rel**
  When called at the end of a QueryProxy chain, it will return the resultant relationship objects intead of nodes.
  For example, to return the relationship between a given student and their lessons:
    student.lessons.each_rel do |rel|

  .. hidden-code-block:: ruby

     def each_rel(&block)
       block_given? ? each(false, true, &block) : to_enum(:each, false, true)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyEnumerable#each_with_rel`:

**#each_with_rel**
  When called at the end of a QueryProxy chain, it will return the nodes and relationships of the last link.
  For example, to return a lesson and each relationship to a given student:
    student.lessons.each_with_rel do |lesson, rel|

  .. hidden-code-block:: ruby

     def each_with_rel(&block)
       block_given? ? each(true, true, &block) : to_enum(:each, true, true)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyEnumerable#pluck`:

**#pluck**
  For getting variables which have been defined as part of the association chain

  .. hidden-code-block:: ruby

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





