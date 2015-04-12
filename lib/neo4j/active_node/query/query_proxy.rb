module Neo4j
  module ActiveNode
    module Query
      class QueryProxy
        include Neo4j::ActiveNode::Query::QueryProxyEnumerable
        include Neo4j::ActiveNode::Query::QueryProxyMethods
        include Neo4j::ActiveNode::Query::QueryProxyFindInBatches
        include Neo4j::ActiveNode::Dependent::QueryProxyMethods

        # The most recent node to start a QueryProxy chain.
        # Will be nil when using QueryProxy chains on class methods.
        attr_reader :source_object, :association, :model, :starting_query

        # QueryProxy is ActiveNode's Cypher DSL. While the name might imply that it creates queries in a general sense,
        # it is actually referring to <tt>Neo4j::Core::Query</tt>, which is a pure Ruby Cypher DSL provided by the <tt>neo4j-core</tt> gem.
        # QueryProxy provides ActiveRecord-like methods for common patterns. When it's not handling CRUD for relationships and queries, it
        # provides ActiveNode's association chaining (`student.lessons.teachers.where(age: 30).hobbies`) and enjoys long walks on the
        # beach.
        #
        # It should not ever be necessary to instantiate a new QueryProxy object directly, it always happens as a result of
        # calling a method that makes use of it.
        #
        # @param [Constant] model The class which included ActiveNode (typically a model, hence the name) from which the query
        # originated.
        # @param [Neo4j::ActiveNode::HasN::Association] association The ActiveNode association (an object created by a <tt>has_one</tt> or
        # <tt>has_many</tt>) that created this object.
        # @param [Hash] options Additional options pertaining to the QueryProxy object. These may include:
        # * node_var: A string or symbol to be used by Cypher within its query string as an identifier
        # * rel_var:  Same as above but pertaining to a relationship identifier
        # * session: The session to be used for this query
        # * source_object:  The node instance at the start of the QueryProxy chain
        # * query_proxy: An existing QueryProxy chain upon which this new object should be built
        #
        # QueryProxy objects are evaluated lazily.
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

        def inspect
          clear, yellow, cyan = %W(\e[0m \e[33m \e[36m)

          "<QueryProxy #{cyan}#{@context}#{clear} CYPHER: #{yellow}#{self.to_cypher.inspect}#{clear}>"
        end

        attr_reader :start_object, :query_proxy

        # The current node identifier on deck, so to speak. It is the object that will be returned by calling `each` and the last node link
        # in the QueryProxy chain.
        attr_reader :node_var
        def identity
          @node_var || _result_string
        end
        alias_method :node_identity, :identity

        # The relationship identifier most recently used by the QueryProxy chain.
        attr_reader :rel_var
        def rel_identity
          ActiveSupport::Deprecation.warn 'rel_identity is deprecated and may be removed from future releases, use rel_var instead.', caller

          @rel_var
        end

        def params(params)
          new_link.tap { |new_query| new_query._add_params(params) }
        end

        # Like calling #query_as, but for when you don't care about the variable name
        def query
          query_as(identity)
        end

        # Build a Neo4j::Core::Query object for the QueryProxy. This is necessary when you want to take an existing QueryProxy chain
        # and work with it from the more powerful (but less friendly) Neo4j::Core::Query.
        # @param [String,Symbol] var The identifier to use for node at this link of the QueryProxy chain.
        #   student.lessons.query_as(:l).with('your cypher here...')
        def query_as(var)
          result_query = @chain.inject(base_query(var).params(@params)) do |query, link|
            args = link.args(var, rel_var)

            if args.is_a?(Array)
              query.send(link.clause, *args)
            else
              query.send(link.clause, link.args(var, rel_var))
            end
          end

          result_query.tap { |query| query.proxy_chain_level = _chain_level }
        end

        def base_query(var)
          if @association
            chain_var = _association_chain_var
            (_association_query_start(chain_var) & _query).send(@match_type,
                                                                "#{chain_var}#{_association_arrow}(#{var}#{_model_label_string})")
          else
            starting_query ? (starting_query & _query_model_as(var)) : _query_model_as(var)
          end
        end

        def _model_label_string
          return if !@model

          @model.mapped_label_names.map { |label_name| ":`#{label_name}`" }.join
        end

        # Scope all queries to the current scope.
        #
        #   Comment.where(post_id: 1).scoping do
        #     Comment.first
        #   end
        #
        # TODO: unscoped
        # Please check unscoped if you want to remove all previous scopes (including
        # the default_scope) during the execution of a block.
        def scoping
          previous, @model.current_scope = @model.current_scope, self
          yield
        ensure
          @model.current_scope = previous
        end

        METHODS = %w(where rel_where order skip limit)

        METHODS.each do |method|
          define_method(method) { |*args| build_deeper_query_proxy(method.to_sym, args) }
        end
        # Since there is a rel_where method, it seems only natural for there to be node_where
        alias_method :node_where, :where
        alias_method :offset, :skip
        alias_method :order_by, :order

        # Cypher string for the QueryProxy's query. This will not include params. For the full output, see <tt>to_cypher_with_params</tt>.
        def to_cypher
          query.to_cypher
        end

        # Returns a string of the cypher query with return objects and params
        # @param [Array] columns array containing symbols of identifiers used in the query
        # @return [String]
        def to_cypher_with_params(columns = [self.identity])
          final_query = query.return_query(columns)
          "#{final_query.to_cypher} | params: #{final_query.send(:merge_params)}"
        end

        # To add a relationship for the node for the association on this QueryProxy
        def <<(other_node)
          create(other_node, {})

          self
        end

        def [](index)
          # TODO: Maybe for this and other methods, use array if already loaded, otherwise
          # use OFFSET and LIMIT 1?
          self.to_a[index]
        end

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

            @start_object.association_proxy_cache.clear

            _create_relationship(other_node, properties)

            @association.perform_callback(@start_object, other_node, :after)
            # end
          end
        end

        def rels
          fail 'Cannot get rels without a relationship variable.' if !@rel_var

          pluck(@rel_var)
        end

        def rel
          rels.first
        end

        def _nodeify(*args)
          [args].flatten.map do |arg|
            (arg.is_a?(Integer) || arg.is_a?(String)) ? @model.find(arg) : arg
          end.compact
        end

        def _create_relationship(other_node_or_nodes, properties)
          _session.query(context: @options[:context])
            .match(:start, :end)
            .where(start: {neo_id: @start_object}, end: {neo_id: other_node_or_nodes})
            .send(association.create_method, "start#{_association_arrow(properties, true)}end").exec
        end

        def read_attribute_for_serialization(*args)
          to_a.map { |o| o.read_attribute_for_serialization(*args) }
        end

        # QueryProxy objects act as a representation of a model at the class level so we pass through calls
        # This allows us to define class functions for reusable query chaining or for end-of-query aggregation/summarizing
        def method_missing(method_name, *args, &block)
          if @model && @model.respond_to?(method_name)
            args[2] = self if @model.association?(method_name) || @model.scope?(method_name)
            scoping { @model.public_send(method_name, *args, &block) }
          else
            super
          end
        end

        def respond_to?(method_name)
          (@model && @model.respond_to?(method_name)) || super
        end

        # Give ability to call `#find` on associations to get a scoped find
        # Doesn't pass through via `method_missing` because Enumerable has a `#find` method
        def find(*args)
          scoping { @model.find(*args) }
        end

        def optional?
          @optional == true
        end

        attr_reader :context

        def new_link(node_var = nil)
          self.clone.tap do |new_query_proxy|
            new_query_proxy.instance_variable_set('@node_var', node_var) if node_var
          end
        end

        protected

        # Methods are underscored to prevent conflict with user class methods
        def _add_params(params)
          @params = @params.merge(params)
        end

        def _add_links(links)
          @chain += links
        end

        def _query_model_as(var)
          _query.send(@match_type, _match_arg(var))
        end

        def _match_arg(var)
          if @model
            labels = @model.respond_to?(:mapped_label_names) ? _model_label_string : @model
            {var => labels}
          else
            var
          end
        end

        def _query
          _session.query(context: @context)
        end

        # TODO: Refactor this. Too much happening here.
        def _result_string
          s = (self.association && self.association.name) || (self.model && self.model.name) || ''

          s ? "result_#{s}".downcase.tr(':', '').to_sym : :result
        end

        def _session
          @session || (@model && @model.neo4j_session)
        end

        def _association_arrow(properties = {}, create = false)
          @association && @association.arrow_cypher(@rel_var, properties, create)
        end

        def _chain_level
          (@query_proxy ? @query_proxy._chain_level : (@chain_level || 0)) + 1
        end

        def _association_chain_var
          if start_object
            :"#{start_object.class.name.gsub('::', '_').downcase}#{start_object.neo_id}"
          elsif @query_proxy
            @query_proxy.node_var || :"node#{_chain_level}"
          else
            fail 'Crazy error' # TODO: Better error
          end
        end

        def _association_query_start(var)
          if object = (start_object || @query_proxy)
            object.query_as(var)
          else
            fail 'Crazy error' # TODO: Better error
          end
        end

        def _rel_chain_var
          :"rel#{_chain_level - 1}"
        end

        attr_writer :context

        private

        def build_deeper_query_proxy(method, args)
          new_link.tap do |new_query|
            Link.for_args(@model, method, args).each do |link|
              new_query._add_links(link)
            end
          end
        end
      end
    end
  end
end
