QueryProxy
==========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   QueryProxy/Link




Constants
---------



  * METHODS



Files
-----



  * `lib/neo4j/active_node/query/query_proxy.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy.rb#L4>`_

  * `lib/neo4j/active_node/query/query_proxy_link.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_link.rb#L4>`_





Methods
-------



.. _`Neo4j/ActiveNode/Query/QueryProxy#<<`:

**#<<**
  To add a relationship for the node for the association on this QueryProxy

  .. hidden-code-block:: ruby

     def <<(other_node)
       create(other_node, {})
     
       self
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#==`:

**#==**
  Does exactly what you would hope. Without it, comparing `bobby.lessons == sandy.lessons` would evaluate to false because it
  would be comparing the QueryProxy objects, not the lessons themselves.

  .. hidden-code-block:: ruby

     def ==(other)
       self.to_a == other
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#[]`:

**#[]**
  

  .. hidden-code-block:: ruby

     def [](index)
       # TODO: Maybe for this and other methods, use array if already loaded, otherwise
       # use OFFSET and LIMIT 1?
       self.to_a[index]
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#_create_relationship`:

**#_create_relationship**
  

  .. hidden-code-block:: ruby

     def _create_relationship(other_node_or_nodes, properties)
       _session.query(context: @options[:context])
         .match(:start, :end)
         .where(start: {neo_id: @start_object}, end: {neo_id: other_node_or_nodes})
         .send(association.create_method, "start#{_association_arrow(properties, true)}end").exec
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#_model_label_string`:

**#_model_label_string**
  

  .. hidden-code-block:: ruby

     def _model_label_string
       return if !@model
       @model.mapped_label_names.map { |label_name| ":`#{label_name}`" }.join
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#_nodeify`:

**#_nodeify**
  

  .. hidden-code-block:: ruby

     def _nodeify(*args)
       [args].flatten.map do |arg|
         (arg.is_a?(Integer) || arg.is_a?(String)) ? @model.find(arg) : arg
       end.compact
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#all_rels_to`:

**#all_rels_to**
  Returns all relationships across a QueryProxy chain between a given node or array of nodes and the preceeding link.

  .. hidden-code-block:: ruby

     def rels_to(node)
       self.match_to(node).pluck(rel_var)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#as_models`:

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



.. _`Neo4j/ActiveNode/Query/QueryProxy#association`:

**#association**
  The most recent node to start a QueryProxy chain.
  Will be nil when using QueryProxy chains on class methods.

  .. hidden-code-block:: ruby

     def association
       @association
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#base_query`:

**#base_query**
  

  .. hidden-code-block:: ruby

     def base_query(var, with_labels = true)
       if @association
         chain_var = _association_chain_var
         (_association_query_start(chain_var) & _query).send(@match_type,
                                                             "#{chain_var}#{_association_arrow}(#{var}#{_model_label_string})")
       else
         starting_query ? (starting_query & _query_model_as(var, with_labels)) : _query_model_as(var, with_labels)
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#blank?`:

**#blank?**
  

  .. hidden-code-block:: ruby

     def empty?(target = nil)
       query_with_target(target) { |var| !self.exists?(nil, var) }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#context`:

**#context**
  Returns the value of attribute context

  .. hidden-code-block:: ruby

     def context
       @context
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#count`:

**#count**
  

  .. hidden-code-block:: ruby

     def count(distinct = nil, target = nil)
       fail(InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
       query_with_target(target) do |var|
         q = distinct.nil? ? var : "DISTINCT #{var}"
         self.query.reorder.pluck("count(#{q}) AS #{var}").first
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#create`:

**#create**
  

  .. hidden-code-block:: ruby

     def create(other_nodes, properties)
       fail 'Can only create relationships on associations' if !@association
       other_nodes = _nodeify(*other_nodes)
     
       properties = @association.inject_classname(properties)
     
       if @model && other_nodes.any? { |other_node| !other_node.is_a?(@model) }
         fail ArgumentError, "Node must be of the association's class when model is specified"
       end
     
       other_nodes.each do |other_node|
         # Neo4j::Transaction.run do
         other_node.save unless other_node.neo_id
     
         return false if @association.perform_callback(@start_object, other_node, :before) == false
     
         @start_object.association_proxy_cache.clear
     
         _create_relationship(other_node, properties)
     
         @association.perform_callback(@start_object, other_node, :after)
         # end
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#delete`:

**#delete**
  Deletes the relationship between a node and its last link in the QueryProxy chain. Executed in the database, callbacks will not run.

  .. hidden-code-block:: ruby

     def delete(node)
       self.match_to(node).query.delete(rel_var).exec
       clear_source_object_cache
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#delete_all`:

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
         clear_source_object_cache
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#delete_all_rels`:

**#delete_all_rels**
  Deletes the relationships between all nodes for the last step in the QueryProxy chain.  Executed in the database, callbacks will not be run.

  .. hidden-code-block:: ruby

     def delete_all_rels
       self.query.delete(rel_var).exec
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#destroy`:

**#destroy**
  Returns all relationships between a node and its last link in the QueryProxy chain, destroys them in Ruby. Callbacks will be run.

  .. hidden-code-block:: ruby

     def destroy(node)
       self.rels_to(node).map!(&:destroy)
       clear_source_object_cache
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#each`:

**#each**
  Just like every other <tt>each</tt> but it allows for optional params to support the versions that also return relationships.
  The <tt>node</tt> and <tt>rel</tt> params are typically used by those other methods but there's nothing stopping you from
  using `your_node.each(true, true)` instead of `your_node.each_with_rel`.

  .. hidden-code-block:: ruby

     def each(node = true, rel = nil, &block)
       pluck_vars = []
       pluck_vars << identity if node
       pluck_vars << @rel_var if rel
     
       pluck(*pluck_vars).each(&block)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#each_for_destruction`:

**#each_for_destruction**
  Used as part of `dependent: :destroy` and may not have any utility otherwise.
  It keeps track of the node responsible for a cascading `destroy` process.
  but this is not always available, so we require it explicitly.

  .. hidden-code-block:: ruby

     def each_for_destruction(owning_node)
       target = owning_node.called_by || owning_node
       objects = pluck(identity).compact.reject do |obj|
         target.dependent_children.include?(obj)
       end
     
       objects.each do |obj|
         obj.called_by = target
         target.dependent_children << obj
         yield obj
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#each_rel`:

**#each_rel**
  When called at the end of a QueryProxy chain, it will return the resultant relationship objects intead of nodes.
  For example, to return the relationship between a given student and their lessons:
    student.lessons.each_rel do |rel|

  .. hidden-code-block:: ruby

     def each_rel(&block)
       block_given? ? each(false, true, &block) : to_enum(:each, false, true)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#each_with_rel`:

**#each_with_rel**
  When called at the end of a QueryProxy chain, it will return the nodes and relationships of the last link.
  For example, to return a lesson and each relationship to a given student:
    student.lessons.each_with_rel do |lesson, rel|

  .. hidden-code-block:: ruby

     def each_with_rel(&block)
       block_given? ? each(true, true, &block) : to_enum(:each, true, true)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#empty?`:

**#empty?**
  

  .. hidden-code-block:: ruby

     def empty?(target = nil)
       query_with_target(target) { |var| !self.exists?(nil, var) }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#exists?`:

**#exists?**
  

  .. hidden-code-block:: ruby

     def exists?(node_condition = nil, target = nil)
       fail(InvalidParameterError, ':exists? only accepts neo_ids') unless node_condition.is_a?(Integer) || node_condition.is_a?(Hash) || node_condition.nil?
       query_with_target(target) do |var|
         start_q = exists_query_start(node_condition, var)
         start_q.query.return("COUNT(#{var}) AS count").first.count > 0
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#find`:

**#find**
  Give ability to call `#find` on associations to get a scoped find
  Doesn't pass through via `method_missing` because Enumerable has a `#find` method

  .. hidden-code-block:: ruby

     def find(*args)
       scoping { @model.find(*args) }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#find_each`:

**#find_each**
  

  .. hidden-code-block:: ruby

     def find_each(options = {})
       query.return(identity).find_each(identity, @model.primary_key, options) do |result|
         yield result
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#find_in_batches`:

**#find_in_batches**
  

  .. hidden-code-block:: ruby

     def find_in_batches(options = {})
       query.return(identity).find_in_batches(identity, @model.primary_key, options) do |batch|
         yield batch
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#first`:

**#first**
  

  .. hidden-code-block:: ruby

     def first(target = nil)
       query_with_target(target) { |var| first_and_last("ID(#{var})", var) }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#first_and_last`:

**#first_and_last**
  

  .. hidden-code-block:: ruby

     def first_and_last(order, target)
       self.order(order).limit(1).pluck(target).first
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#first_rel_to`:

**#first_rel_to**
  Gives you the first relationship between the last link of a QueryProxy chain and a given node
  Shorthand for `MATCH (start)-[r]-(other_node) WHERE ID(other_node) = #{other_node.neo_id} RETURN r`

  .. hidden-code-block:: ruby

     def first_rel_to(node)
       self.match_to(node).limit(1).pluck(rel_var).first
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#identity`:

**#identity**
  

  .. hidden-code-block:: ruby

     def identity
       @node_var || _result_string
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#include?`:

**#include?**
  

  .. hidden-code-block:: ruby

     def include?(other, target = nil)
       fail(InvalidParameterError, ':include? only accepts nodes') unless other.respond_to?(:neo_id)
       query_with_target(target) do |var|
         self.where("ID(#{var}) = {other_node_id}").params(other_node_id: other.neo_id).query.return("count(#{var}) as count").first.count > 0
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#initialize`:

**#initialize**
  QueryProxy is ActiveNode's Cypher DSL. While the name might imply that it creates queries in a general sense,
  it is actually referring to <tt>Neo4j::Core::Query</tt>, which is a pure Ruby Cypher DSL provided by the <tt>neo4j-core</tt> gem.
  QueryProxy provides ActiveRecord-like methods for common patterns. When it's not handling CRUD for relationships and queries, it
  provides ActiveNode's association chaining (`student.lessons.teachers.where(age: 30).hobbies`) and enjoys long walks on the
  beach.
  
  It should not ever be necessary to instantiate a new QueryProxy object directly, it always happens as a result of
  calling a method that makes use of it.
  
  originated.
  <tt>has_many</tt>) that created this object.
  * node_var: A string or symbol to be used by Cypher within its query string as an identifier
  * rel_var:  Same as above but pertaining to a relationship identifier
  * session: The session to be used for this query
  * source_object:  The node instance at the start of the QueryProxy chain
  * query_proxy: An existing QueryProxy chain upon which this new object should be built
  
  QueryProxy objects are evaluated lazily.

  .. hidden-code-block:: ruby

     def initialize(model, association = nil, options = {})
       @model = model
       @association = association
       @context = options.delete(:context)
       @options = options
     
       @node_var, @session, @source_object, @starting_query, @optional, @start_object, @query_proxy, @chain_level =
         options.values_at(:node, :session, :source_object, :starting_query, :optional, :start_object, :query_proxy, :chain_level)
     
       @match_type = @optional ? :optional_match : :match
     
       @rel_var = options[:rel] || _rel_chain_var
     
       @chain = []
       @params = @query_proxy ? @query_proxy.instance_variable_get('@params') : {}
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#inspect`:

**#inspect**
  

  .. hidden-code-block:: ruby

     def inspect
       clear, yellow, cyan = %W(\e[0m \e[33m \e[36m)
     
       "<QueryProxy #{cyan}#{@context}#{clear} CYPHER: #{yellow}#{self.to_cypher.inspect}#{clear}>"
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#last`:

**#last**
  

  .. hidden-code-block:: ruby

     def last(target = nil)
       query_with_target(target) { |var| first_and_last("ID(#{var}) DESC", var) }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#length`:

**#length**
  

  .. hidden-code-block:: ruby

     def count(distinct = nil, target = nil)
       fail(InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
       query_with_target(target) do |var|
         q = distinct.nil? ? var : "DISTINCT #{var}"
         self.query.reorder.pluck("count(#{q}) AS #{var}").first
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#match_to`:

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



.. _`Neo4j/ActiveNode/Query/QueryProxy#method_missing`:

**#method_missing**
  QueryProxy objects act as a representation of a model at the class level so we pass through calls
  This allows us to define class functions for reusable query chaining or for end-of-query aggregation/summarizing

  .. hidden-code-block:: ruby

     def method_missing(method_name, *args, &block)
       if @model && @model.respond_to?(method_name)
         scoping { @model.public_send(method_name, *args, &block) }
       else
         super
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#model`:

**#model**
  The most recent node to start a QueryProxy chain.
  Will be nil when using QueryProxy chains on class methods.

  .. hidden-code-block:: ruby

     def model
       @model
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#new_link`:

**#new_link**
  

  .. hidden-code-block:: ruby

     def new_link(node_var = nil)
       self.clone.tap do |new_query_proxy|
         new_query_proxy.instance_variable_set('@node_var', node_var) if node_var
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#node_identity`:

**#node_identity**
  

  .. hidden-code-block:: ruby

     def identity
       @node_var || _result_string
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#node_var`:

**#node_var**
  The current node identifier on deck, so to speak. It is the object that will be returned by calling `each` and the last node link
  in the QueryProxy chain.

  .. hidden-code-block:: ruby

     def node_var
       @node_var
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#node_where`:

**#node_where**
  Since there is a rel_where method, it seems only natural for there to be node_where

  .. hidden-code-block:: ruby

     alias_method :node_where, :where



.. _`Neo4j/ActiveNode/Query/QueryProxy#offset`:

**#offset**
  

  .. hidden-code-block:: ruby

     alias_method :offset, :skip



.. _`Neo4j/ActiveNode/Query/QueryProxy#optional`:

**#optional**
  A shortcut for attaching a new, optional match to the end of a QueryProxy chain.

  .. hidden-code-block:: ruby

     def optional(association, node_var = nil, rel_var = nil)
       self.send(association, node_var, rel_var, optional: true)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#optional?`:

**#optional?**
  

  .. hidden-code-block:: ruby

     def optional?
       @optional == true
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#order_by`:

**#order_by**
  

  .. hidden-code-block:: ruby

     alias_method :order_by, :order



.. _`Neo4j/ActiveNode/Query/QueryProxy#params`:

**#params**
  

  .. hidden-code-block:: ruby

     def params(params)
       new_link.tap { |new_query| new_query._add_params(params) }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#pluck`:

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



.. _`Neo4j/ActiveNode/Query/QueryProxy#query`:

**#query**
  Like calling #query_as, but for when you don't care about the variable name

  .. hidden-code-block:: ruby

     def query
       query_as(identity)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#query_as`:

**#query_as**
  Build a Neo4j::Core::Query object for the QueryProxy. This is necessary when you want to take an existing QueryProxy chain
  and work with it from the more powerful (but less friendly) Neo4j::Core::Query.

  .. hidden-code-block:: ruby

     def query_as(var, with_label = true)
       result_query = @chain.inject(base_query(var, with_label).params(@params)) do |query, link|
         args = link.args(var, rel_var)
     
         if args.is_a?(Array)
           query.send(link.clause, *args)
         else
           query.send(link.clause, link.args(var, rel_var))
         end
       end
     
       result_query.tap { |query| query.proxy_chain_level = _chain_level }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#query_proxy`:

**#query_proxy**
  Returns the value of attribute query_proxy

  .. hidden-code-block:: ruby

     def query_proxy
       @query_proxy
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#read_attribute_for_serialization`:

**#read_attribute_for_serialization**
  

  .. hidden-code-block:: ruby

     def read_attribute_for_serialization(*args)
       to_a.map { |o| o.read_attribute_for_serialization(*args) }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#rel`:

**#rel**
  

  .. hidden-code-block:: ruby

     def rel
       rels.first
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#rel_identity`:

**#rel_identity**
  

  .. hidden-code-block:: ruby

     def rel_identity
       ActiveSupport::Deprecation.warn 'rel_identity is deprecated and may be removed from future releases, use rel_var instead.', caller
     
       @rel_var
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#rel_var`:

**#rel_var**
  The relationship identifier most recently used by the QueryProxy chain.

  .. hidden-code-block:: ruby

     def rel_var
       @rel_var
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#rels`:

**#rels**
  

  .. hidden-code-block:: ruby

     def rels
       fail 'Cannot get rels without a relationship variable.' if !@rel_var
     
       pluck(@rel_var)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#rels_to`:

**#rels_to**
  Returns all relationships across a QueryProxy chain between a given node or array of nodes and the preceeding link.

  .. hidden-code-block:: ruby

     def rels_to(node)
       self.match_to(node).pluck(rel_var)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#replace_with`:

**#replace_with**
  Deletes the relationships between all nodes for the last step in the QueryProxy chain and replaces them with relationships to the given nodes.
  Executed in the database, callbacks will not be run.

  .. hidden-code-block:: ruby

     def replace_with(node_or_nodes)
       nodes = Array(node_or_nodes)
     
       self.delete_all_rels
       nodes.each { |node| self << node }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#respond_to?`:

**#respond_to?**
  

  .. hidden-code-block:: ruby

     def respond_to?(method_name)
       (@model && @model.respond_to?(method_name)) || super
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#scoping`:

**#scoping**
  Scope all queries to the current scope.
  
    Comment.where(post_id: 1).scoping do
      Comment.first
    end
  
  TODO: unscoped
  Please check unscoped if you want to remove all previous scopes (including
  the default_scope) during the execution of a block.

  .. hidden-code-block:: ruby

     def scoping
       previous = @model.current_scope
       @model.current_scope = self
       yield
     ensure
       @model.current_scope = previous
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#size`:

**#size**
  

  .. hidden-code-block:: ruby

     def count(distinct = nil, target = nil)
       fail(InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
       query_with_target(target) do |var|
         q = distinct.nil? ? var : "DISTINCT #{var}"
         self.query.reorder.pluck("count(#{q}) AS #{var}").first
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#source_object`:

**#source_object**
  The most recent node to start a QueryProxy chain.
  Will be nil when using QueryProxy chains on class methods.

  .. hidden-code-block:: ruby

     def source_object
       @source_object
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#start_object`:

**#start_object**
  Returns the value of attribute start_object

  .. hidden-code-block:: ruby

     def start_object
       @start_object
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#starting_query`:

**#starting_query**
  The most recent node to start a QueryProxy chain.
  Will be nil when using QueryProxy chains on class methods.

  .. hidden-code-block:: ruby

     def starting_query
       @starting_query
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#to_cypher`:

**#to_cypher**
  Cypher string for the QueryProxy's query. This will not include params. For the full output, see <tt>to_cypher_with_params</tt>.

  .. hidden-code-block:: ruby

     def to_cypher
       query.to_cypher
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#to_cypher_with_params`:

**#to_cypher_with_params**
  Returns a string of the cypher query with return objects and params

  .. hidden-code-block:: ruby

     def to_cypher_with_params(columns = [self.identity])
       final_query = query.return_query(columns)
       "#{final_query.to_cypher} | params: #{final_query.send(:merge_params)}"
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#unique_nodes`:

**#unique_nodes**
  This will match nodes who only have a single relationship of a given type.
  It's used  by `dependent: :delete_orphans` and `dependent: :destroy_orphans` and may not have much utility otherwise.

  .. hidden-code-block:: ruby

     def unique_nodes(association, self_identifer, other_node, other_rel)
       fail 'Only supported by in QueryProxy chains started by an instance' unless source_object
     
       unique_nodes_query(association, self_identifer, other_node, other_rel)
         .proxy_as(association.target_class, other_node)
     end





