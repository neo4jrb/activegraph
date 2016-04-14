QueryProxyMethods
=================






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------



  * FIRST

  * LAST



Files
-----



  * `lib/neo4j/active_node/query/query_proxy_methods.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_methods.rb#L4>`_





Methods
-------



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#all_rels_to`:

**#all_rels_to**
  Returns all relationships across a QueryProxy chain between a given node or array of nodes and the preceeding link.

  .. code-block:: ruby

     def rels_to(node)
       self.match_to(node).pluck(rel_var)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#as_models`:

**#as_models**
  Takes an Array of ActiveNode models and applies the appropriate WHERE clause
  So for a `Teacher` model inheriting from a `Person` model and an `Article` model
  if you called .as_models([Teacher, Article])
  The where clause would look something like:
  
  .. code-block:: cypher
  
    WHERE (node_var:Teacher:Person OR node_var:Article)

  .. code-block:: ruby

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
  

  .. code-block:: ruby

     def empty?(target = nil)
       query_with_target(target) { |var| !self.exists?(nil, var) }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#count`:

**#count**
  

  .. code-block:: ruby

     def count(distinct = nil, target = nil)
       fail(Neo4j::InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
       query_with_target(target) do |var|
         q = distinct.nil? ? var : "DISTINCT #{var}"
         limited_query = self.query.clause?(:limit) ? self.query.break.with(var) : self.query.reorder
         limited_query.pluck("count(#{q}) AS #{var}").first
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#empty?`:

**#empty?**
  

  .. code-block:: ruby

     def empty?(target = nil)
       query_with_target(target) { |var| !self.exists?(nil, var) }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#exists?`:

**#exists?**
  

  .. code-block:: ruby

     def exists?(node_condition = nil, target = nil)
       unless node_condition.is_a?(Integer) || node_condition.is_a?(Hash) || node_condition.nil?
         fail(Neo4j::InvalidParameterError, ':exists? only accepts neo_ids')
       end
       query_with_target(target) do |var|
         start_q = exists_query_start(node_condition, var)
         start_q.query.reorder.return("COUNT(#{var}) AS count").first.count > 0
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#find`:

**#find**
  Give ability to call `#find` on associations to get a scoped find
  Doesn't pass through via `method_missing` because Enumerable has a `#find` method

  .. code-block:: ruby

     def find(*args)
       scoping { @model.find(*args) }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#find_or_create_by`:

**#find_or_create_by**
  When called, this method returns a single node that satisfies the match specified in the params hash.
  If no existing node is found to satisfy the match, one is created or associated as expected.

  .. code-block:: ruby

     def find_or_create_by(params)
       fail 'Method invalid when called on Class objects' unless source_object
       result = self.where(params).first
       return result unless result.nil?
       Neo4j::Transaction.run do
         node = model.find_or_create_by(params)
         self << node
         return node
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#first`:

**#first**
  

  .. code-block:: ruby

     def first(target = nil)
       first_and_last(FIRST, target)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#first_rel_to`:

**#first_rel_to**
  Gives you the first relationship between the last link of a QueryProxy chain and a given node
  Shorthand for `MATCH (start)-[r]-(other_node) WHERE ID(other_node) = #{other_node.neo_id} RETURN r`

  .. code-block:: ruby

     def first_rel_to(node)
       self.match_to(node).limit(1).pluck(rel_var).first
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#include?`:

**#include?**
  

  .. code-block:: ruby

     def include?(other, target = nil)
       query_with_target(target) do |var|
         where_filter = if other.respond_to?(:neo_id)
                          "ID(#{var}) = {other_node_id}"
                        else
                          "#{var}.#{association_id_key} = {other_node_id}"
                        end
         node_id = other.respond_to?(:neo_id) ? other.neo_id : other
         self.where(where_filter).params(other_node_id: node_id).query.reorder.return("count(#{var}) as count").first.count > 0
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#last`:

**#last**
  

  .. code-block:: ruby

     def last(target = nil)
       first_and_last(LAST, target)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#limit_value`:

**#limit_value**
  TODO: update this with public API methods if/when they are exposed

  .. code-block:: ruby

     def limit_value
       return unless self.query.clause?(:limit)
       limit_clause = self.query.send(:clauses).find { |clause| clause.is_a?(Neo4j::Core::QueryClauses::LimitClause) }
       limit_clause.instance_variable_get(:@arg)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#match_to`:

**#match_to**
  Shorthand for `MATCH (start)-[r]-(other_node) WHERE ID(other_node) = #{other_node.neo_id}`
  The `node` param can be a persisted ActiveNode instance, any string or integer, or nil.
  When it's a node, it'll use the object's neo_id, which is fastest. When not nil, it'll figure out the
  primary key of that model. When nil, it uses `1 = 2` to prevent matching all records, which is the default
  behavior when nil is passed to `where` in QueryProxy.

  .. code-block:: ruby

     def match_to(node)
       first_node = node.is_a?(Array) ? node.first : node
       where_arg = if first_node.respond_to?(:neo_id)
                     {neo_id: node.is_a?(Array) ? node.map(&:neo_id) : node}
                   elsif !node.nil?
                     {association_id_key => node.is_a?(Array) ? ids_array(node) : node}
                   else
                     # support for null object pattern
                     '1 = 2'
                   end
     
       self.where(where_arg)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#optional`:

**#optional**
  A shortcut for attaching a new, optional match to the end of a QueryProxy chain.

  .. code-block:: ruby

     def optional(association, node_var = nil, rel_var = nil)
       self.send(association, node_var, rel_var, optional: true)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#order_property`:

**#order_property**
  

  .. code-block:: ruby

     def order_property
       # This should maybe be based on a setting in the association
       # rather than a hardcoded `nil`
       model ? model.id_property_name : nil
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#rel`:

**#rel**
  

  .. code-block:: ruby

     def rel
       rels.first
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#rels`:

**#rels**
  

  .. code-block:: ruby

     def rels
       fail 'Cannot get rels without a relationship variable.' if !@rel_var
     
       pluck(@rel_var)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#rels_to`:

**#rels_to**
  Returns all relationships across a QueryProxy chain between a given node or array of nodes and the preceeding link.

  .. code-block:: ruby

     def rels_to(node)
       self.match_to(node).pluck(rel_var)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethods#size`:

**#size**
  

  .. code-block:: ruby

     def size
       result_cache? ? result_cache_for.length : count
     end





