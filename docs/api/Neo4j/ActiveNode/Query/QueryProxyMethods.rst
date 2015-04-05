QueryProxyMethods
=================




.. toctree::
   :maxdepth: 3
   :titlesonly:


   QueryProxyMethods/InvalidParameterError

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/query/query_proxy_methods.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_methods.rb#L4>`_





Methods
-------



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#all_rels_to`:

**#all_rels_to**
  Returns all relationships across a QueryProxy chain between a given node or array of nodes and the preceeding link.

  .. hidden-code-block:: ruby

     def rels_to(node)
       self.match_to(node).pluck(rel_var)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#as_models`:

**#as_models**
  Takes an Array of ActiveNode models and applies the appropriate WHERE clause
  So for a `Teacher` model inheriting from a `Person` model and an `Article` model
  if you called .as_models([Teacher, Article])
  The where clause would look something like:
    WHERE (node_var:Teacher:Person OR node_var:Article)

  .. hidden-code-block:: ruby

     def as_models(models)
       where_clause = models.map do |model|
         "`#{identity}`:" + model.mapped_label_names.map do |mapped_label_name|
           "`#{mapped_label_name}`"
         end.join(':')
       end.join(' OR ')
     
       where("(#{where_clause})")
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#blank?`:

**#blank?**
  

  .. hidden-code-block:: ruby

     def empty?(target = nil)
       query_with_target(target) { |var| !self.exists?(nil, var) }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#count`:

**#count**
  

  .. hidden-code-block:: ruby

     def count(distinct = nil, target = nil)
       fail(InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
       query_with_target(target) do |var|
         q = distinct.nil? ? var : "DISTINCT #{var}"
         self.query.reorder.pluck("count(#{q}) AS #{var}").first
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#delete`:

**#delete**
  Deletes the relationship between a node and its last link in the QueryProxy chain. Executed in the database, callbacks will not run.

  .. hidden-code-block:: ruby

     def delete(node)
       self.match_to(node).query.delete(rel_var).exec
       clear_caller_cache
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#delete_all`:

**#delete_all**
  Deletes a group of nodes and relationships within a QP chain. When identifier is omitted, it will remove the last link in the chain.
  The optional argument must be a node identifier. A relationship identifier will result in a Cypher Error

  .. hidden-code-block:: ruby

     def delete_all(identifier = nil)
       query_with_target(identifier) do |target|
         begin
           self.query.with(target).optional_match("(#{target})-[#{target}_rel]-()").delete("#{target}, #{target}_rel").exec
         rescue Neo4j::Session::CypherError
           self.query.delete(target).exec
         end
         clear_caller_cache
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#delete_all_rels`:

**#delete_all_rels**
  Deletes the relationships between all nodes for the last step in the QueryProxy chain.  Executed in the database, callbacks will not be run.

  .. hidden-code-block:: ruby

     def delete_all_rels
       self.query.delete(rel_var).exec
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#destroy`:

**#destroy**
  Returns all relationships between a node and its last link in the QueryProxy chain, destroys them in Ruby. Callbacks will be run.

  .. hidden-code-block:: ruby

     def destroy(node)
       self.rels_to(node).map!(&:destroy)
       clear_caller_cache
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#empty?`:

**#empty?**
  

  .. hidden-code-block:: ruby

     def empty?(target = nil)
       query_with_target(target) { |var| !self.exists?(nil, var) }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#exists?`:

**#exists?**
  

  .. hidden-code-block:: ruby

     def exists?(node_condition = nil, target = nil)
       fail(InvalidParameterError, ':exists? only accepts neo_ids') unless node_condition.is_a?(Integer) || node_condition.is_a?(Hash) || node_condition.nil?
       query_with_target(target) do |var|
         start_q = exists_query_start(node_condition, var)
         start_q.query.return("COUNT(#{var}) AS count").first.count > 0
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#first`:

**#first**
  

  .. hidden-code-block:: ruby

     def first(target = nil)
       query_with_target(target) { |var| first_and_last("ID(#{var})", var) }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#first_and_last`:

**#first_and_last**
  

  .. hidden-code-block:: ruby

     def first_and_last(order, target)
       self.order(order).limit(1).pluck(target).first
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#first_rel_to`:

**#first_rel_to**
  Gives you the first relationship between the last link of a QueryProxy chain and a given node
  Shorthand for `MATCH (start)-[r]-(other_node) WHERE ID(other_node) = #{other_node.neo_id} RETURN r`

  .. hidden-code-block:: ruby

     def first_rel_to(node)
       self.match_to(node).limit(1).pluck(rel_var).first
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#include?`:

**#include?**
  

  .. hidden-code-block:: ruby

     def include?(other, target = nil)
       fail(InvalidParameterError, ':include? only accepts nodes') unless other.respond_to?(:neo_id)
       query_with_target(target) do |var|
         self.where("ID(#{var}) = {other_node_id}").params(other_node_id: other.neo_id).query.return("count(#{var}) as count").first.count > 0
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#last`:

**#last**
  

  .. hidden-code-block:: ruby

     def last(target = nil)
       query_with_target(target) { |var| first_and_last("ID(#{var}) DESC", var) }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#length`:

**#length**
  

  .. hidden-code-block:: ruby

     def count(distinct = nil, target = nil)
       fail(InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
       query_with_target(target) do |var|
         q = distinct.nil? ? var : "DISTINCT #{var}"
         self.query.reorder.pluck("count(#{q}) AS #{var}").first
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#match_to`:

**#match_to**
  Shorthand for `MATCH (start)-[r]-(other_node) WHERE ID(other_node) = #{other_node.neo_id}`
  The `node` param can be a persisted ActiveNode instance, any string or integer, or nil.
  When it's a node, it'll use the object's neo_id, which is fastest. When not nil, it'll figure out the
  primary key of that model. When nil, it uses `1 = 2` to prevent matching all records, which is the default
  behavior when nil is passed to `where` in QueryProxy.

  .. hidden-code-block:: ruby

     def match_to(node)
       where_arg = if node.respond_to?(:neo_id)
                     {neo_id: node.neo_id}
                   elsif !node.nil?
                     node = ids_array(node) if node.is_a?(Array)
                     {association_id_key => node}
                   else
                     # support for null object pattern
                     '1 = 2'
                   end
       self.where(where_arg)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#optional`:

**#optional**
  A shortcut for attaching a new, optional match to the end of a QueryProxy chain.

  .. hidden-code-block:: ruby

     def optional(association, node_var = nil, rel_var = nil)
       self.send(association, node_var, rel_var, nil, optional: true)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#rels_to`:

**#rels_to**
  Returns all relationships across a QueryProxy chain between a given node or array of nodes and the preceeding link.

  .. hidden-code-block:: ruby

     def rels_to(node)
       self.match_to(node).pluck(rel_var)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#replace_with`:

**#replace_with**
  Deletes the relationships between all nodes for the last step in the QueryProxy chain and replaces them with relationships to the given nodes.
  Executed in the database, callbacks will not be run.

  .. hidden-code-block:: ruby

     def replace_with(node_or_nodes)
       nodes = Array(node_or_nodes)
     
       self.delete_all_rels
       nodes.each { |node| self << node }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#size`:

**#size**
  

  .. hidden-code-block:: ruby

     def count(distinct = nil, target = nil)
       fail(InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
       query_with_target(target) do |var|
         q = distinct.nil? ? var : "DISTINCT #{var}"
         self.query.reorder.pluck("count(#{q}) AS #{var}").first
       end
     end





