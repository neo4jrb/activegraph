QueryProxy
==========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   QueryProxy/Link




Constants
---------



  * METHODS

  * FIRST

  * LAST



Files
-----



  * `lib/neo4j/active_node/query/query_proxy.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy.rb#L4>`_

  * `lib/neo4j/active_node/query/query_proxy_link.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_link.rb#L4>`_





Methods
-------



.. _`Neo4j/ActiveNode/Query/QueryProxy#<<`:

**#<<**
  To add a relationship for the node for the association on this QueryProxy

  .. code-block:: ruby

     def <<(other_node)
       if @start_object._persisted_obj
         create(other_node, {})
       elsif @association
         @start_object.defer_create(@association.name, other_node)
       else
         fail 'Another crazy error!'
       end
       self
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#==`:

**#==**
  Does exactly what you would hope. Without it, comparing `bobby.lessons == sandy.lessons` would evaluate to false because it
  would be comparing the QueryProxy objects, not the lessons themselves.

  .. code-block:: ruby

     def ==(other)
       self.to_a == other
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#[]`:

**#[]**
  

  .. code-block:: ruby

     def [](index)
       # TODO: Maybe for this and other methods, use array if already loaded, otherwise
       # use OFFSET and LIMIT 1?
       self.to_a[index]
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#_create_relationship`:

**#_create_relationship**
  

  .. code-block:: ruby

     def _create_relationship(other_node_or_nodes, properties)
       association._create_relationship(@start_object, other_node_or_nodes, properties)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#_model_label_string`:

**#_model_label_string**
  param [TrueClass, FalseClass] with_labels This param is used by certain QueryProxy methods that already have the neo_id and
  therefore do not need labels.
  The @association_labels instance var is set during init and used during association chaining to keep labels out of Cypher queries.

  .. code-block:: ruby

     def _model_label_string(with_labels = true)
       return if !@model || (!with_labels || @association_labels == false)
       @model.mapped_label_names.map { |label_name| ":`#{label_name}`" }.join
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#_nodeify!`:

**#_nodeify!**
  

  .. code-block:: ruby

     def _nodeify!(*args)
       other_nodes = [args].flatten!.map! do |arg|
         (arg.is_a?(Integer) || arg.is_a?(String)) ? @model.find_by(id: arg) : arg
       end.compact
     
       if @model && other_nodes.any? { |other_node| !other_node.class.mapped_label_names.include?(@model.mapped_label_name) }
         fail ArgumentError, "Node must be of the association's class when model is specified"
       end
     
       other_nodes
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#all_rels_to`:

**#all_rels_to**
  Returns all relationships across a QueryProxy chain between a given node or array of nodes and the preceeding link.

  .. code-block:: ruby

     def rels_to(node)
       self.match_to(node).pluck(rel_var)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#as_models`:

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



.. _`Neo4j/ActiveNode/Query/QueryProxy#association`:

**#association**
  The most recent node to start a QueryProxy chain.
  Will be nil when using QueryProxy chains on class methods.

  .. code-block:: ruby

     def association
       @association
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#base_query`:

**#base_query**
  

  .. code-block:: ruby

     def base_query(var, with_labels = true)
       if @association
         chain_var = _association_chain_var
         (_association_query_start(chain_var) & _query).break.send(@match_type,
                                                                   "#{chain_var}#{_association_arrow}(#{var}#{_model_label_string})")
       else
         starting_query ? starting_query : _query_model_as(var, with_labels)
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#blank?`:

**#blank?**
  

  .. code-block:: ruby

     def empty?(target = nil)
       query_with_target(target) { |var| !self.exists?(nil, var) }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#branch`:

**#branch**
  Executes the relation chain specified in the block, while keeping the current scope

  .. code-block:: ruby

     def branch(&block)
       if block
         instance_eval(&block).query.proxy_as(self.model, identity)
       else
         fail LocalJumpError, 'no block given'
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#context`:

**#context**
  Returns the value of attribute context

  .. code-block:: ruby

     def context
       @context
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#count`:

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



.. _`Neo4j/ActiveNode/Query/QueryProxy#create`:

**#create**
  

  .. code-block:: ruby

     def create(other_nodes, properties)
       fail 'Can only create relationships on associations' if !@association
       other_nodes = _nodeify!(*other_nodes)
     
       Neo4j::Transaction.run do
         other_nodes.each do |other_node|
           other_node.save unless other_node.neo_id
     
           return false if @association.perform_callback(@start_object, other_node, :before) == false
     
           @start_object.association_proxy_cache.clear
     
           _create_relationship(other_node, properties)
     
           @association.perform_callback(@start_object, other_node, :after)
         end
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#delete`:

**#delete**
  Deletes the relationship between a node and its last link in the QueryProxy chain. Executed in the database, callbacks will not run.

  .. code-block:: ruby

     def delete(node)
       self.match_to(node).query.delete(rel_var).exec
       clear_source_object_cache
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#delete_all`:

**#delete_all**
  Deletes a group of nodes and relationships within a QP chain. When identifier is omitted, it will remove the last link in the chain.
  The optional argument must be a node identifier. A relationship identifier will result in a Cypher Error

  .. code-block:: ruby

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

  .. code-block:: ruby

     def delete_all_rels
       return unless start_object && start_object._persisted_obj
       self.query.delete(rel_var).exec
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#destroy`:

**#destroy**
  Returns all relationships between a node and its last link in the QueryProxy chain, destroys them in Ruby. Callbacks will be run.

  .. code-block:: ruby

     def destroy(node)
       self.rels_to(node).map!(&:destroy)
       clear_source_object_cache
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#each`:

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



.. _`Neo4j/ActiveNode/Query/QueryProxy#each_for_destruction`:

**#each_for_destruction**
  Used as part of `dependent: :destroy` and may not have any utility otherwise.
  It keeps track of the node responsible for a cascading `destroy` process.
  but this is not always available, so we require it explicitly.

  .. code-block:: ruby

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
  
  .. code-block:: ruby
  
    student.lessons.each_rel do |rel|

  .. code-block:: ruby

     def each_rel(&block)
       block_given? ? each(false, true, &block) : to_enum(:each, false, true)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#each_with_rel`:

**#each_with_rel**
  When called at the end of a QueryProxy chain, it will return the nodes and relationships of the last link.
  For example, to return a lesson and each relationship to a given student:
  
  .. code-block:: ruby
  
    student.lessons.each_with_rel do |lesson, rel|

  .. code-block:: ruby

     def each_with_rel(&block)
       block_given? ? each(true, true, &block) : to_enum(:each, true, true)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#empty?`:

**#empty?**
  

  .. code-block:: ruby

     def empty?(target = nil)
       query_with_target(target) { |var| !self.exists?(nil, var) }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#exists?`:

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



.. _`Neo4j/ActiveNode/Query/QueryProxy#fetch_result_cache`:

**#fetch_result_cache**
  

  .. code-block:: ruby

     def fetch_result_cache
       @result_cache ||= yield
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#find`:

**#find**
  Give ability to call `#find` on associations to get a scoped find
  Doesn't pass through via `method_missing` because Enumerable has a `#find` method

  .. code-block:: ruby

     def find(*args)
       scoping { @model.find(*args) }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#find_each`:

**#find_each**
  

  .. code-block:: ruby

     def find_each(options = {})
       query.return(identity).find_each(identity, @model.primary_key, options) do |result|
         yield result.send(identity)
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#find_in_batches`:

**#find_in_batches**
  

  .. code-block:: ruby

     def find_in_batches(options = {})
       query.return(identity).find_in_batches(identity, @model.primary_key, options) do |batch|
         yield batch.map(&:identity)
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#find_or_create_by`:

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



.. _`Neo4j/ActiveNode/Query/QueryProxy#first`:

**#first**
  

  .. code-block:: ruby

     def first(target = nil)
       first_and_last(FIRST, target)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#first_rel_to`:

**#first_rel_to**
  Gives you the first relationship between the last link of a QueryProxy chain and a given node
  Shorthand for `MATCH (start)-[r]-(other_node) WHERE ID(other_node) = #{other_node.neo_id} RETURN r`

  .. code-block:: ruby

     def first_rel_to(node)
       self.match_to(node).limit(1).pluck(rel_var).first
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#identity`:

**#identity**
  

  .. code-block:: ruby

     def identity
       @node_var || _result_string
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#include?`:

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
  QueryProxy objects are evaluated lazily.

  .. code-block:: ruby

     def initialize(model, association = nil, options = {})
       @model = model
       @association = association
       @context = options.delete(:context)
       @options = options
       @associations_spec = []
     
       instance_vars_from_options!(options)
     
       @match_type = @optional ? :optional_match : :match
     
       @rel_var = options[:rel] || _rel_chain_var
     
       @chain = []
       @params = @query_proxy ? @query_proxy.instance_variable_get('@params') : {}
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#inspect`:

**#inspect**
  

  .. code-block:: ruby

     def inspect
       "#<QueryProxy #{@context} CYPHER: #{self.to_cypher.inspect}>"
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#last`:

**#last**
  

  .. code-block:: ruby

     def last(target = nil)
       first_and_last(LAST, target)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#limit_value`:

**#limit_value**
  TODO: update this with public API methods if/when they are exposed

  .. code-block:: ruby

     def limit_value
       return unless self.query.clause?(:limit)
       limit_clause = self.query.send(:clauses).find { |clause| clause.is_a?(Neo4j::Core::QueryClauses::LimitClause) }
       limit_clause.instance_variable_get(:@arg)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#match_to`:

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



.. _`Neo4j/ActiveNode/Query/QueryProxy#method_missing`:

**#method_missing**
  QueryProxy objects act as a representation of a model at the class level so we pass through calls
  This allows us to define class functions for reusable query chaining or for end-of-query aggregation/summarizing

  .. code-block:: ruby

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

  .. code-block:: ruby

     def model
       @model
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#new_link`:

**#new_link**
  

  .. code-block:: ruby

     def new_link(node_var = nil)
       self.clone.tap do |new_query_proxy|
         new_query_proxy.instance_variable_set('@result_cache', nil)
         new_query_proxy.instance_variable_set('@node_var', node_var) if node_var
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#node_identity`:

**#node_identity**
  

  .. code-block:: ruby

     def identity
       @node_var || _result_string
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#node_order`:

**#node_order**
  

  .. code-block:: ruby

     alias_method :node_order, :order



.. _`Neo4j/ActiveNode/Query/QueryProxy#node_var`:

**#node_var**
  The current node identifier on deck, so to speak. It is the object that will be returned by calling `each` and the last node link
  in the QueryProxy chain.

  .. code-block:: ruby

     def node_var
       @node_var
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#node_where`:

**#node_where**
  Since there are rel_where and rel_order methods, it seems only natural for there to be node_where and node_order

  .. code-block:: ruby

     alias_method :node_where, :where



.. _`Neo4j/ActiveNode/Query/QueryProxy#offset`:

**#offset**
  

  .. code-block:: ruby

     alias_method :offset, :skip



.. _`Neo4j/ActiveNode/Query/QueryProxy#optional`:

**#optional**
  A shortcut for attaching a new, optional match to the end of a QueryProxy chain.

  .. code-block:: ruby

     def optional(association, node_var = nil, rel_var = nil)
       self.send(association, node_var, rel_var, optional: true)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#optional?`:

**#optional?**
  

  .. code-block:: ruby

     def optional?
       @optional == true
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#order_by`:

**#order_by**
  

  .. code-block:: ruby

     alias_method :order_by, :order



.. _`Neo4j/ActiveNode/Query/QueryProxy#order_property`:

**#order_property**
  

  .. code-block:: ruby

     def order_property
       # This should maybe be based on a setting in the association
       # rather than a hardcoded `nil`
       model ? model.id_property_name : nil
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#params`:

**#params**
  

  .. code-block:: ruby

     def params(params)
       new_link.tap { |new_query| new_query._add_params(params) }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#pluck`:

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



.. _`Neo4j/ActiveNode/Query/QueryProxy#query`:

**#query**
  Like calling #query_as, but for when you don't care about the variable name

  .. code-block:: ruby

     def query
       query_as(identity)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#query_as`:

**#query_as**
  Build a Neo4j::Core::Query object for the QueryProxy. This is necessary when you want to take an existing QueryProxy chain
  and work with it from the more powerful (but less friendly) Neo4j::Core::Query.
  .. code-block:: ruby
  
    student.lessons.query_as(:l).with('your cypher here...')

  .. code-block:: ruby

     def query_as(var, with_labels = true)
       result_query = @chain.inject(base_query(var, with_labels).params(@params)) do |query, link|
         args = link.args(var, rel_var)
     
         args.is_a?(Array) ? query.send(link.clause, *args) : query.send(link.clause, args)
       end
     
       result_query.tap { |query| query.proxy_chain_level = _chain_level }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#query_proxy`:

**#query_proxy**
  Returns the value of attribute query_proxy

  .. code-block:: ruby

     def query_proxy
       @query_proxy
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#read_attribute_for_serialization`:

**#read_attribute_for_serialization**
  

  .. code-block:: ruby

     def read_attribute_for_serialization(*args)
       to_a.map { |o| o.read_attribute_for_serialization(*args) }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#rel`:

**#rel**
  

  .. code-block:: ruby

     def rel
       rels.first
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#rel_identity`:

**#rel_identity**
  

  .. code-block:: ruby

     def rel_identity
       ActiveSupport::Deprecation.warn 'rel_identity is deprecated and may be removed from future releases, use rel_var instead.', caller
     
       @rel_var
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#rel_var`:

**#rel_var**
  The relationship identifier most recently used by the QueryProxy chain.

  .. code-block:: ruby

     def rel_var
       @rel_var
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#rels`:

**#rels**
  

  .. code-block:: ruby

     def rels
       fail 'Cannot get rels without a relationship variable.' if !@rel_var
     
       pluck(@rel_var)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#rels_to`:

**#rels_to**
  Returns all relationships across a QueryProxy chain between a given node or array of nodes and the preceeding link.

  .. code-block:: ruby

     def rels_to(node)
       self.match_to(node).pluck(rel_var)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#replace_with`:

**#replace_with**
  Deletes the relationships between all nodes for the last step in the QueryProxy chain and replaces them with relationships to the given nodes.
  Executed in the database, callbacks will not be run.

  .. code-block:: ruby

     def replace_with(node_or_nodes)
       nodes = Array(node_or_nodes)
     
       self.delete_all_rels
       nodes.each { |node| self << node }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#respond_to_missing?`:

**#respond_to_missing?**
  

  .. code-block:: ruby

     def respond_to_missing?(method_name, include_all = false)
       (@model && @model.respond_to?(method_name, include_all)) || super
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#result`:

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



.. _`Neo4j/ActiveNode/Query/QueryProxy#result_cache?`:

**#result_cache?**
  

  .. code-block:: ruby

     def result_cache?(node = true, rel = nil)
       !!result_cache_for(node, rel)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#result_cache_for`:

**#result_cache_for**
  

  .. code-block:: ruby

     def result_cache_for(node = true, rel = nil)
       (@result_cache || {})[[node, rel]]
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#scoping`:

**#scoping**
  Scope all queries to the current scope.
  
  .. code-block:: ruby
  
    Comment.where(post_id: 1).scoping do
      Comment.first
    end
  
  TODO: unscoped
  Please check unscoped if you want to remove all previous scopes (including
  the default_scope) during the execution of a block.

  .. code-block:: ruby

     def scoping
       previous = @model.current_scope
       @model.current_scope = self
       yield
     ensure
       @model.current_scope = previous
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#size`:

**#size**
  

  .. code-block:: ruby

     def size
       result_cache? ? result_cache_for.length : count
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#source_object`:

**#source_object**
  The most recent node to start a QueryProxy chain.
  Will be nil when using QueryProxy chains on class methods.

  .. code-block:: ruby

     def source_object
       @source_object
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#start_object`:

**#start_object**
  Returns the value of attribute start_object

  .. code-block:: ruby

     def start_object
       @start_object
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#starting_query`:

**#starting_query**
  The most recent node to start a QueryProxy chain.
  Will be nil when using QueryProxy chains on class methods.

  .. code-block:: ruby

     def starting_query
       @starting_query
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#to_cypher_with_params`:

**#to_cypher_with_params**
  Returns a string of the cypher query with return objects and params

  .. code-block:: ruby

     def to_cypher_with_params(columns = [self.identity])
       final_query = query.return_query(columns)
       "#{final_query.to_cypher} | params: #{final_query.send(:merge_params)}"
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#unique_nodes`:

**#unique_nodes**
  This will match nodes who only have a single relationship of a given type.
  It's used  by `dependent: :delete_orphans` and `dependent: :destroy_orphans` and may not have much utility otherwise.

  .. code-block:: ruby

     def unique_nodes(association, self_identifer, other_node, other_rel)
       fail 'Only supported by in QueryProxy chains started by an instance' unless source_object
       return false if send(association.name).empty?
       unique_nodes_query(association, self_identifer, other_node, other_rel)
         .proxy_as(association.target_class, other_node)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#update_all`:

**#update_all**
  Updates some attributes of a group of nodes within a QP chain.
  The optional argument makes sense only of `updates` is a string.

  .. code-block:: ruby

     def update_all(updates, params = {})
       # Move this to ActiveNode module?
       update_all_with_query(identity, updates, params)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#update_all_rels`:

**#update_all_rels**
  Updates some attributes of a group of relationships within a QP chain.
  The optional argument makes sense only of `updates` is a string.

  .. code-block:: ruby

     def update_all_rels(updates, params = {})
       fail 'Cannot update rels without a relationship variable.' unless @rel_var
       update_all_with_query(@rel_var, updates, params)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#with_associations`:

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



.. _`Neo4j/ActiveNode/Query/QueryProxy#with_associations_return_clause`:

**#with_associations_return_clause**
  

  .. code-block:: ruby

     def with_associations_return_clause
       '[' + with_associations_spec.map { |n| "collect(#{n})" }.join(',') + ']'
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy#with_associations_spec`:

**#with_associations_spec**
  

  .. code-block:: ruby

     def with_associations_spec
       @with_associations_spec ||= []
     end





