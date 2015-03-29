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



  * lib/neo4j/active_node/query/query_proxy.rb:4

  * lib/neo4j/active_node/query/query_proxy_link.rb:4





Methods
-------


**#<<**
  To add a relationship for the node for the association on this QueryProxy

  .. hidden-code-block:: ruby

     def <<(other_node)
       create(other_node, {})
     
       self
     end


**#==**
  Does exactly what you would hope. Without it, comparing `bobby.lessons == sandy.lessons` would evaluate to false because it
  would be comparing the QueryProxy objects, not the lessons themselves.

  .. hidden-code-block:: ruby

     def ==(other)
       self.to_a == other
     end


**#[]**
  

  .. hidden-code-block:: ruby

     def [](index)
       # TODO: Maybe for this and other methods, use array if already loaded, otherwise
       # use OFFSET and LIMIT 1?
       self.to_a[index]
     end


**#_add_links**
  

  .. hidden-code-block:: ruby

     def _add_links(links)
       @chain += links
     end


**#_add_params**
  Methods are underscored to prevent conflict with user class methods

  .. hidden-code-block:: ruby

     def _add_params(params)
       @params = @params.merge(params)
     end


**#_association_arrow**
  

  .. hidden-code-block:: ruby

     def _association_arrow(properties = {}, create = false)
       @association && @association.arrow_cypher(@rel_var, properties, create)
     end


**#_association_chain_var**
  

  .. hidden-code-block:: ruby

     def _association_chain_var
       if start_object
         :"#{start_object.class.name.gsub('::', '_').downcase}#{start_object.neo_id}"
       elsif @query_proxy
         @query_proxy.node_var || :"node#{_chain_level}"
       else
         fail 'Crazy error' # TODO: Better error
       end
     end


**#_association_query_start**
  

  .. hidden-code-block:: ruby

     def _association_query_start(var)
       if object = (start_object || @query_proxy)
         object.query_as(var)
       else
         fail 'Crazy error' # TODO: Better error
       end
     end


**#_chain_level**
  

  .. hidden-code-block:: ruby

     def _chain_level
       (@query_proxy ? @query_proxy._chain_level : (@chain_level || 0)) + 1
     end


**#_create_relationship**
  

  .. hidden-code-block:: ruby

     def _create_relationship(other_node_or_nodes, properties)
       _session.query(context: @options[:context])
         .match(:start, :end)
         .where(start: {neo_id: @start_object}, end: {neo_id: other_node_or_nodes})
         .send(create_method, "start#{_association_arrow(properties, true)}end").exec
     end


**#_match_arg**
  

  .. hidden-code-block:: ruby

     def _match_arg(var)
       if @model
         labels = @model.respond_to?(:mapped_label_names) ? _model_label_string : @model
         {var => labels}
       else
         var
       end
     end


**#_model_label_string**
  

  .. hidden-code-block:: ruby

     def _model_label_string
       return if !@model
     
       @model.mapped_label_names.map { |label_name| ":`#{label_name}`" }.join
     end


**#_nodeify**
  

  .. hidden-code-block:: ruby

     def _nodeify(*args)
       [args].flatten.map do |arg|
         (arg.is_a?(Integer) || arg.is_a?(String)) ? @model.find(arg) : arg
       end.compact
     end


**#_query**
  

  .. hidden-code-block:: ruby

     def _query
       _session.query(context: @context)
     end


**#_query_model_as**
  

  .. hidden-code-block:: ruby

     def _query_model_as(var)
       _query.send(@match_type, _match_arg(var))
     end


**#_rel_chain_var**
  

  .. hidden-code-block:: ruby

     def _rel_chain_var
       :"rel#{_chain_level - 1}"
     end


**#_result_string**
  TODO: Refactor this. Too much happening here.

  .. hidden-code-block:: ruby

     def _result_string
       s = (self.association && self.association.name) ||
           (self.model && self.model.name) || ''
     
       s ? "result_#{s}".downcase.tr(':', '').to_sym : :result
     end


**#_session**
  

  .. hidden-code-block:: ruby

     def _session
       @session || (@model && @model.neo4j_session)
     end


**#all_rels_to**
  Returns all relationships across a QueryProxy chain between a given node or array of nodes and the preceeding link.

  .. hidden-code-block:: ruby

     def rels_to(node)
       self.match_to(node).pluck(rel_var)
     end


**#association**
  The most recent node to start a QueryProxy chain.
  Will be nil when using QueryProxy chains on class methods.

  .. hidden-code-block:: ruby

     def association
       @association
     end


**#association_id_key**
  

  .. hidden-code-block:: ruby

     def association_id_key
       self.association.nil? ? model.primary_key : self.association.target_class.primary_key
     end


**#base_query**
  

  .. hidden-code-block:: ruby

     def base_query(var)
       if @association
         chain_var = _association_chain_var
         (_association_query_start(chain_var) & _query).send(@match_type,
                                                             "#{chain_var}#{_association_arrow}(#{var}#{_model_label_string})")
       else
         starting_query ? (starting_query & _query_model_as(var)) : _query_model_as(var)
       end
     end


**#blank?**
  

  .. hidden-code-block:: ruby

     def empty?(target = nil)
       query_with_target(target) { |var| !self.exists?(nil, var) }
     end


**#build_deeper_query_proxy**
  

  .. hidden-code-block:: ruby

     def build_deeper_query_proxy(method, args)
       self.dup.tap do |new_query|
         args.each do |arg|
           new_query._add_links(links_for_arg(method, arg))
         end
       end
     end


**#caller**
  The most recent node to start a QueryProxy chain.
  Will be nil when using QueryProxy chains on class methods.

  .. hidden-code-block:: ruby

     def caller
       @caller
     end


**#clear_caller_cache**
  

  .. hidden-code-block:: ruby

     def clear_caller_cache
       self.caller.clear_association_cache if self.caller.respond_to?(:clear_association_cache)
     end


**#context**
  Returns the value of attribute context

  .. hidden-code-block:: ruby

     def context
       @context
     end


**#context=**
  Sets the attribute context

  .. hidden-code-block:: ruby

     def context=(value)
       @context = value
     end


**#count**
  

  .. hidden-code-block:: ruby

     def count(distinct = nil, target = nil)
       fail(InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
       query_with_target(target) do |var|
         q = distinct.nil? ? var : "DISTINCT #{var}"
         self.query.reorder.pluck("count(#{q}) AS #{var}").first
       end
     end


**#create**
  

  .. hidden-code-block:: ruby

     def create(other_nodes, properties)
       fail 'Can only create associations on associations' unless @association
       other_nodes = _nodeify(*other_nodes)
     
       properties = @association.inject_classname(properties)
     
       if @model && other_nodes.any? { |other_node| !other_node.is_a?(@model) }
         fail ArgumentError, "Node must be of the association's class when model is specified"
       end
     
       other_nodes.each do |other_node|
         # Neo4j::Transaction.run do
         other_node.save unless other_node.neo_id
     
         return false if @association.perform_callback(@start_object, other_node, :before) == false
     
         @start_object.clear_association_cache
     
         _create_relationship(other_node, properties)
     
         @association.perform_callback(@start_object, other_node, :after)
         # end
       end
     end


**#create_method**
  

  .. hidden-code-block:: ruby

     def create_method
       association.unique? ? :create_unique : :create
     end


**#delete**
  Deletes the relationship between a node and its last link in the QueryProxy chain. Executed in the database, callbacks will not run.

  .. hidden-code-block:: ruby

     def delete(node)
       self.match_to(node).query.delete(rel_var).exec
       clear_caller_cache
     end


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


**#delete_all_rels**
  Deletes the relationships between all nodes for the last step in the QueryProxy chain.  Executed in the database, callbacks will not be run.

  .. hidden-code-block:: ruby

     def delete_all_rels
       self.query.delete(rel_var).exec
     end


**#destroy**
  Returns all relationships between a node and its last link in the QueryProxy chain, destroys them in Ruby. Callbacks will be run.

  .. hidden-code-block:: ruby

     def destroy(node)
       self.rels_to(node).map!(&:destroy)
       clear_caller_cache
     end


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


**#each_for_destruction**
  Used as part of `dependent: :destroy` and may not have any utility otherwise.
  It keeps track of the node responsible for a cascading `destroy` process.
  but this is not always available, so we require it explicitly.

  .. hidden-code-block:: ruby

     def each_for_destruction(owning_node)
       target = owning_node.called_by || owning_node
       objects = enumerable_query(identity).compact.reject do |obj|
         target.dependent_children.include?(obj)
       end
     
       objects.each do |obj|
         obj.called_by = target
         target.dependent_children << obj
         yield obj
       end
     end


**#each_rel**
  When called at the end of a QueryProxy chain, it will return the resultant relationship objects intead of nodes.
  For example, to return the relationship between a given student and their lessons:
    student.lessons.each_rel do |rel|

  .. hidden-code-block:: ruby

     def each_rel(&block)
       block_given? ? each(false, true, &block) : to_enum(:each, false, true)
     end


**#each_with_rel**
  When called at the end of a QueryProxy chain, it will return the nodes and relationships of the last link.
  For example, to return a lesson and each relationship to a given student:
    student.lessons.each_with_rel do |lesson, rel|

  .. hidden-code-block:: ruby

     def each_with_rel(&block)
       block_given? ? each(true, true, &block) : to_enum(:each, true, true)
     end


**#empty?**
  

  .. hidden-code-block:: ruby

     def empty?(target = nil)
       query_with_target(target) { |var| !self.exists?(nil, var) }
     end


**#enumerable_query**
  Executes the query against the database if the results are not already present in a node's association cache. This method is
  shared by <tt>each</tt>, <tt>each_rel</tt>, and <tt>each_with_rel</tt>.

  .. hidden-code-block:: ruby

     def enumerable_query(node, rel = nil)
       pluck_this = rel.nil? ? [node] : [node, rel]
       return self.pluck(*pluck_this) if @association.nil? || caller.nil?
       cypher_string = self.to_cypher_with_params(pluck_this)
       association_collection = caller.association_instance_get(cypher_string, @association)
       if association_collection.nil?
         association_collection = self.pluck(*pluck_this)
         caller.association_instance_set(cypher_string, association_collection, @association) unless association_collection.empty?
       end
       association_collection
     end


**#exists?**
  

  .. hidden-code-block:: ruby

     def exists?(node_condition = nil, target = nil)
       fail(InvalidParameterError, ':exists? only accepts neo_ids') unless node_condition.is_a?(Integer) || node_condition.is_a?(Hash) || node_condition.nil?
       query_with_target(target) do |var|
         start_q = exists_query_start(node_condition, var)
         start_q.query.return("COUNT(#{var}) AS count").first.count > 0
       end
     end


**#exists_query_start**
  

  .. hidden-code-block:: ruby

     def exists_query_start(condition, target)
       case condition
       when Integer
         self.where("ID(#{target}) = {exists_condition}").params(exists_condition: condition)
       when Hash
         self.where(condition.keys.first => condition.values.first)
       else
         self
       end
     end


**#find**
  Give ability to call `#find` on associations to get a scoped find
  Doesn't pass through via `method_missing` because Enumerable has a `#find` method

  .. hidden-code-block:: ruby

     def find(*args)
       scoping { @model.find(*args) }
     end


**#find_each**
  

  .. hidden-code-block:: ruby

     def find_each(options = {})
       query.return(identity).find_each(identity, @model.primary_key, options) do |result|
         yield result
       end
     end


**#find_in_batches**
  

  .. hidden-code-block:: ruby

     def find_in_batches(options = {})
       query.return(identity).find_in_batches(identity, @model.primary_key, options) do |batch|
         yield batch
       end
     end


**#first**
  

  .. hidden-code-block:: ruby

     def first(target = nil)
       query_with_target(target) { |var| first_and_last("ID(#{var})", var) }
     end


**#first_and_last**
  

  .. hidden-code-block:: ruby

     def first_and_last(order, target)
       self.order(order).limit(1).pluck(target).first
     end


**#first_rel_to**
  Gives you the first relationship between the last link of a QueryProxy chain and a given node
  Shorthand for `MATCH (start)-[r]-(other_node) WHERE ID(other_node) = #{other_node.neo_id} RETURN r`

  .. hidden-code-block:: ruby

     def first_rel_to(node)
       self.match_to(node).limit(1).pluck(rel_var).first
     end


**#identity**
  

  .. hidden-code-block:: ruby

     def identity
       @node_var || _result_string
     end


**#ids_array**
  

  .. hidden-code-block:: ruby

     def ids_array(node)
       node.first.respond_to?(:id) ? node.map!(&:id) : node
     end


**#include?**
  

  .. hidden-code-block:: ruby

     def include?(other, target = nil)
       fail(InvalidParameterError, ':include? only accepts nodes') unless other.respond_to?(:neo_id)
       query_with_target(target) do |var|
         self.where("ID(#{var}) = {other_node_id}").params(other_node_id: other.neo_id).query.return("count(#{var}) as count").first.count > 0
       end
     end


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
  * caller:  The node instance at the start of the QueryProxy chain
  * query_proxy: An existing QueryProxy chain upon which this new object should be built
  
  QueryProxy objects are evaluated lazily.

  .. hidden-code-block:: ruby

     def initialize(model, association = nil, options = {})
       @model = model
       @association = association
       @context = options.delete(:context)
       @options = options
     
       @node_var, @session, @caller, @starting_query, @optional, @start_object, @query_proxy, @chain_level =
         options.values_at(:node, :session, :caller, :starting_query, :optional, :start_object, :query_proxy, :chain_level)
     
       @match_type = @optional ? :optional_match : :match
     
       @rel_var = options[:rel] || _rel_chain_var
     
       @chain = []
       @params = @query_proxy ? @query_proxy.instance_variable_get('@params') : {}
     end


**#last**
  

  .. hidden-code-block:: ruby

     def last(target = nil)
       query_with_target(target) { |var| first_and_last("ID(#{var}) DESC", var) }
     end


**#length**
  

  .. hidden-code-block:: ruby

     def count(distinct = nil, target = nil)
       fail(InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
       query_with_target(target) do |var|
         q = distinct.nil? ? var : "DISTINCT #{var}"
         self.query.reorder.pluck("count(#{q}) AS #{var}").first
       end
     end


**#links_for_arg**
  

  .. hidden-code-block:: ruby

     def links_for_arg(clause, arg)
       default = [Link.new(clause, arg)]
     
       Link.for_clause(clause, arg, @model) || default
     rescue NoMethodError
       default
     end


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


**#method_missing**
  QueryProxy objects act as a representation of a model at the class level so we pass through calls
  This allows us to define class functions for reusable query chaining or for end-of-query aggregation/summarizing

  .. hidden-code-block:: ruby

     def method_missing(method_name, *args, &block)
       if @model && @model.respond_to?(method_name)
         args[2] = self if @model.association?(method_name) || @model.scope?(method_name)
         scoping { @model.public_send(method_name, *args, &block) }
       else
         super
       end
     end


**#model**
  The most recent node to start a QueryProxy chain.
  Will be nil when using QueryProxy chains on class methods.

  .. hidden-code-block:: ruby

     def model
       @model
     end


**#node_identity**
  

  .. hidden-code-block:: ruby

     def identity
       @node_var || _result_string
     end


**#node_var**
  The current node identifier on deck, so to speak. It is the object that will be returned by calling `each` and the last node link
  in the QueryProxy chain.

  .. hidden-code-block:: ruby

     def node_var
       @node_var
     end


**#node_where**
  Since there is a rel_where method, it seems only natural for there to be node_where

  .. hidden-code-block:: ruby

     alias_method :node_where, :where


**#offset**
  

  .. hidden-code-block:: ruby

     alias_method :offset, :skip


**#optional**
  A shortcut for attaching a new, optional match to the end of a QueryProxy chain.

  .. hidden-code-block:: ruby

     def optional(association, node_var = nil, rel_var = nil)
       self.send(association, node_var, rel_var, nil, optional: true)
     end


**#optional?**
  

  .. hidden-code-block:: ruby

     def optional?
       @optional == true
     end


**#order_by**
  

  .. hidden-code-block:: ruby

     alias_method :order_by, :order


**#params**
  

  .. hidden-code-block:: ruby

     def params(params)
       self.dup.tap do |new_query|
         new_query._add_params(params)
       end
     end


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


**#query**
  Like calling #query_as, but for when you don't care about the variable name

  .. hidden-code-block:: ruby

     def query
       query_as(identity)
     end


**#query_as**
  Build a Neo4j::Core::Query object for the QueryProxy. This is necessary when you want to take an existing QueryProxy chain
  and work with it from the more powerful (but less friendly) Neo4j::Core::Query.

  .. hidden-code-block:: ruby

     def query_as(var)
       result_query = @chain.inject(base_query(var).params(@params)) do |query, link|
         query.send(link.clause, link.args(var, rel_var))
       end
     
       result_query.tap { |query| query.proxy_chain_level = _chain_level }
     end


**#query_proxy**
  Returns the value of attribute query_proxy

  .. hidden-code-block:: ruby

     def query_proxy
       @query_proxy
     end


**#query_with_target**
  

  .. hidden-code-block:: ruby

     def query_with_target(target)
       yield(target || identity)
     end


**#read_attribute_for_serialization**
  

  .. hidden-code-block:: ruby

     def read_attribute_for_serialization(*args)
       to_a.map { |o| o.read_attribute_for_serialization(*args) }
     end


**#rel**
  

  .. hidden-code-block:: ruby

     def rel
       rels.first
     end


**#rel_identity**
  

  .. hidden-code-block:: ruby

     def rel_identity
       ActiveSupport::Deprecation.warn 'rel_identity is deprecated and may be removed from future releases, use rel_var instead.', caller
     
       @rel_var
     end


**#rel_var**
  The relationship identifier most recently used by the QueryProxy chain.

  .. hidden-code-block:: ruby

     def rel_var
       @rel_var
     end


**#rels**
  

  .. hidden-code-block:: ruby

     def rels
       fail 'Cannot get rels without a relationship variable.' if !@rel_var
     
       pluck(@rel_var)
     end


**#rels_to**
  Returns all relationships across a QueryProxy chain between a given node or array of nodes and the preceeding link.

  .. hidden-code-block:: ruby

     def rels_to(node)
       self.match_to(node).pluck(rel_var)
     end


**#replace_with**
  Deletes the relationships between all nodes for the last step in the QueryProxy chain and replaces them with relationships to the given nodes.
  Executed in the database, callbacks will not be run.

  .. hidden-code-block:: ruby

     def replace_with(node_or_nodes)
       nodes = Array(node_or_nodes)
     
       self.delete_all_rels
       nodes.each { |node| self << node }
     end


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
       previous, @model.current_scope = @model.current_scope, self
       yield
     ensure
       @model.current_scope = previous
     end


**#size**
  

  .. hidden-code-block:: ruby

     def count(distinct = nil, target = nil)
       fail(InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
       query_with_target(target) do |var|
         q = distinct.nil? ? var : "DISTINCT #{var}"
         self.query.reorder.pluck("count(#{q}) AS #{var}").first
       end
     end


**#start_object**
  Returns the value of attribute start_object

  .. hidden-code-block:: ruby

     def start_object
       @start_object
     end


**#starting_query**
  The most recent node to start a QueryProxy chain.
  Will be nil when using QueryProxy chains on class methods.

  .. hidden-code-block:: ruby

     def starting_query
       @starting_query
     end


**#to_cypher**
  Cypher string for the QueryProxy's query. This will not include params. For the full output, see <tt>to_cypher_with_params</tt>.

  .. hidden-code-block:: ruby

     def to_cypher
       query.to_cypher
     end


**#to_cypher_with_params**
  Returns a string of the cypher query with return objects and params

  .. hidden-code-block:: ruby

     def to_cypher_with_params(columns = [self.identity])
       final_query = query.return_query(columns)
       "#{final_query.to_cypher} | params: #{final_query.send(:merge_params)}"
     end


**#unique_nodes**
  This will match nodes who only have a single relationship of a given type.
  It's used  by `dependent: :delete_orphans` and `dependent: :destroy_orphans` and may not have much utility otherwise.

  .. hidden-code-block:: ruby

     def unique_nodes(association, self_identifer, other_node, other_rel)
       fail 'Only supported by in QueryProxy chains started by an instance' unless caller
     
       unique_nodes_query(association, self_identifer, other_node, other_rel)
         .proxy_as(association.target_class, other_node)
     end


**#unique_nodes_query**
  

  .. hidden-code-block:: ruby

     def unique_nodes_query(association, self_identifer, other_node, other_rel)
       query.with(identity).proxy_as_optional(caller.class, self_identifer)
         .send(association.name, other_node, other_rel)
         .query
         .with(other_node)
         .match("()#{association.arrow_cypher}(#{other_node})")
         .with(other_node, count: 'count(*)')
         .where('count = 1')
     end





