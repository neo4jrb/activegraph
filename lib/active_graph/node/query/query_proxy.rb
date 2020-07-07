module ActiveGraph
  module Node
    module Query
      # rubocop:disable Metrics/ClassLength
      class QueryProxy
        # rubocop:enable Metrics/ClassLength
        include ActiveGraph::Node::Query::QueryProxyEnumerable
        include ActiveGraph::Node::Query::QueryProxyMethods
        include ActiveGraph::Node::Query::QueryProxyMethodsOfMassUpdating
        include ActiveGraph::Node::Query::QueryProxyFindInBatches
        include ActiveGraph::Node::Query::QueryProxyEagerLoading
        include ActiveGraph::Node::Dependent::QueryProxyMethods

        # The most recent node to start a QueryProxy chain.
        # Will be nil when using QueryProxy chains on class methods.
        attr_reader :source_object, :association, :model, :starting_query

        # QueryProxy is Node's Cypher DSL. While the name might imply that it creates queries in a general sense,
        # it is actually referring to <tt>ActiveGraph::Core::Query</tt>, which is a pure Ruby Cypher DSL provided by the <tt>activegraph</tt> gem.
        # QueryProxy provides ActiveRecord-like methods for common patterns. When it's not handling CRUD for relationships and queries, it
        # provides Node's association chaining (`student.lessons.teachers.where(age: 30).hobbies`) and enjoys long walks on the
        # beach.
        #
        # It should not ever be necessary to instantiate a new QueryProxy object directly, it always happens as a result of
        # calling a method that makes use of it.
        #
        # @param [Constant] model The class which included Node (typically a model, hence the name) from which the query
        # originated.
        # @param [ActiveGraph::Node::HasN::Association] association The Node association (an object created by a <tt>has_one</tt> or
        # <tt>has_many</tt>) that created this object.
        # @param [Hash] options Additional options pertaining to the QueryProxy object. These may include:
        # @option options [String, Symbol] :node_var A string or symbol to be used by Cypher within its query string as an identifier
        # @option options [String, Symbol] :rel_var Same as above but pertaining to a relationship identifier
        # @option options [Range, Integer, Symbol, Hash] :rel_length A Range, a Integer, a Hash or a Symbol to indicate the variable-length/fixed-length
        #   qualifier of the relationship. See http://neo4jrb.readthedocs.org/en/latest/Querying.html#variable-length-relationships.
        # @option options [ActiveGraph::Node] :source_object The node instance at the start of the QueryProxy chain
        # @option options [QueryProxy] :query_proxy An existing QueryProxy chain upon which this new object should be built
        #
        # QueryProxy objects are evaluated lazily.
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

        def inspect
          formatted_nodes = ActiveGraph::Node::NodeListFormatter.new(to_a)
          "#<QueryProxy #{@context} #{formatted_nodes.inspect}>"
        end

        attr_reader :start_object, :query_proxy

        # The current node identifier on deck, so to speak. It is the object that will be returned by calling `each` and the last node link
        # in the QueryProxy chain.
        attr_reader :node_var
        def identity
          @node_var || _result_string(_chain_level + 1)
        end
        alias node_identity identity

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

        # Build a ActiveGraph::Core::Query object for the QueryProxy. This is necessary when you want to take an existing QueryProxy chain
        # and work with it from the more powerful (but less friendly) ActiveGraph::Core::Query.
        # @param [String,Symbol] var The identifier to use for node at this link of the QueryProxy chain.
        #
        # .. code-block:: ruby
        #
        #   student.lessons.query_as(:l).with('your cypher here...')
        def query_as(var, with_labels = true)
          query_from_chain(chain, base_query(var, with_labels).params(@params), var)
            .tap { |query| query.proxy_chain_level = _chain_level }
        end

        def query_from_chain(chain, base_query, var)
          chain.inject(base_query) do |query, link|
            args = link.args(var, rel_var)

            args.is_a?(Array) ? query.send(link.clause, *args) : query.send(link.clause, args)
          end
        end

        def base_query(var, with_labels = true)
          if @association
            chain_var = _association_chain_var
            (_association_query_start(chain_var) & _query).break.send(@match_type,
                                                                      "(#{chain_var})#{_association_arrow}(#{var}#{_model_label_string})")
          else
            starting_query ? starting_query : _query_model_as(var, with_labels)
          end
        end

        # param [TrueClass, FalseClass] with_labels This param is used by certain QueryProxy methods that already have the neo_id and
        # therefore do not need labels.
        # The @association_labels instance var is set during init and used during association chaining to keep labels out of Cypher queries.
        def _model_label_string(with_labels = true)
          return if !@model || (!with_labels || @association_labels == false)
          @model.mapped_label_names.map { |label_name| ":`#{label_name}`" }.join
        end

        # Scope all queries to the current scope.
        #
        # .. code-block:: ruby
        #
        #   Comment.where(post_id: 1).scoping do
        #     Comment.first
        #   end
        #
        # TODO: unscoped
        # Please check unscoped if you want to remove all previous scopes (including
        # the default_scope) during the execution of a block.
        def scoping
          previous = @model.current_scope
          @model.current_scope = self
          yield
        ensure
          @model.current_scope = previous
        end

        METHODS = %w(where where_not rel_where rel_where_not rel_order order skip limit)

        METHODS.each do |method|
          define_method(method) { |*args| build_deeper_query_proxy(method.to_sym, args) }
        end
        # Since there are rel_where and rel_order methods, it seems only natural for there to be node_where and node_order
        alias node_where where
        alias node_order order
        alias offset skip
        alias order_by order

        # Cypher string for the QueryProxy's query. This will not include params. For the full output, see <tt>to_cypher_with_params</tt>.
        delegate :to_cypher, to: :query

        delegate :print_cypher, to: :query

        # Returns a string of the cypher query with return objects and params
        # @param [Array] columns array containing symbols of identifiers used in the query
        # @return [String]
        def to_cypher_with_params(columns = [self.identity])
          final_query = query.return_query(columns)
          "#{final_query.to_cypher} | params: #{final_query.send(:merge_params)}"
        end

        # To add a relationship for the node for the association on this QueryProxy
        def <<(other_node)
          _create_relation_or_defer(other_node)
          self
        end

        # Executes the relation chain specified in the block, while keeping the current scope
        #
        # @example Load all people that have friends
        #   Person.all.branch { friends }.to_a # => Returns a list of `Person`
        #
        # @example Load all people that has old friends
        #   Person.all.branch { friends.where('age > 70') }.to_a # => Returns a list of `Person`
        #
        # @yield the block that will be evaluated starting from the current scope
        #
        # @return [QueryProxy] A new QueryProxy
        def branch(&block)
          fail LocalJumpError, 'no block given' if block.nil?
          # `as(identity)` is here to make sure we get the right variable
          # There might be a deeper problem of the variable changing when we
          # traverse an association
          as(identity).instance_eval(&block).query.proxy_as(self.model, identity).tap do |new_query_proxy|
            propagate_context(new_query_proxy)
          end
        end

        def [](index)
          # TODO: Maybe for this and other methods, use array if already loaded, otherwise
          # use OFFSET and LIMIT 1?
          self.to_a[index]
        end

        def create(other_nodes, properties = {})
          fail 'Can only create relationships on associations' if !@association
          other_nodes = _nodeify!(*other_nodes)

          ActiveGraph::Base.transaction do
            other_nodes.each do |other_node|
              if other_node.neo_id
                other_node.try(:delete_reverse_has_one_core_rel, association)
              else
                other_node.save
              end

              @start_object.association_proxy_cache.clear

              _create_relationship(other_node, properties)
            end
          end
        end

        def _nodeify!(*args)
          other_nodes = [args].flatten!.map! do |arg|
            (arg.is_a?(Integer) || arg.is_a?(String)) ? @model.find_by(id: arg) : arg
          end.compact

          if @model && other_nodes.any? { |other_node| !other_node.class.mapped_label_names.include?(@model.mapped_label_name) }
            fail ArgumentError, "Node must be of the association's class when model is specified"
          end

          other_nodes
        end

        def _create_relationship(other_node_or_nodes, properties)
          association._create_relationship(@start_object, other_node_or_nodes, properties)
        end

        def read_attribute_for_serialization(*args)
          to_a.map { |o| o.read_attribute_for_serialization(*args) }
        end

        delegate :to_ary, to: :to_a

        # QueryProxy objects act as a representation of a model at the class level so we pass through calls
        # This allows us to define class functions for reusable query chaining or for end-of-query aggregation/summarizing
        def method_missing(method_name, *args, &block)
          if @model && @model.respond_to?(method_name)
            scoping { @model.public_send(method_name, *args, &block) }
          else
            super
          end
        end

        def respond_to_missing?(method_name, include_all = false)
          (@model && @model.respond_to?(method_name, include_all)) || super
        end

        def optional?
          @optional == true
        end

        attr_reader :context

        def new_link(node_var = nil)
          self.clone.tap do |new_query_proxy|
            new_query_proxy.instance_variable_set('@result_cache', nil)
            new_query_proxy.instance_variable_set('@node_var', node_var) if node_var
          end
        end

        def unpersisted_start_object?
          @start_object && @start_object.new_record?
        end

        protected

        def _create_relation_or_defer(other_node)
          if @start_object._persisted_obj
            create(other_node, {})
          elsif @association
            @start_object.defer_create(@association.name, other_node)
          else
            fail 'Another crazy error!'
          end
        end

        # Methods are underscored to prevent conflict with user class methods
        def _add_params(params)
          @params = @params.merge(params)
        end

        def _add_links(links)
          @chain += links
        end

        def _query_model_as(var, with_labels = true)
          _query.break.send(@match_type, _match_arg(var, with_labels))
        end

        # @param [String, Symbol] var The Cypher identifier to use within the match string
        # @param [Boolean] with_labels Send "true" to include model labels where possible.
        def _match_arg(var, with_labels)
          if @model && with_labels != false
            labels = @model.respond_to?(:mapped_label_names) ? _model_label_string : @model
            {var.to_sym => labels}
          else
            var.to_sym
          end
        end

        def _query
          ActiveGraph::Base.new_query(context: @context)
        end

        def _result_string(index = nil)
          "result_#{(association || model).try(:name)}#{index}".downcase.tr(':', '').to_sym
        end

        def _association_arrow(properties = {}, create = false)
          @association && @association.arrow_cypher(@rel_var, properties, create, false, @rel_length)
        end

        def _chain_level
          (@query_proxy ? @query_proxy._chain_level : (@chain_level || 0)) + 1
        end

        def _association_chain_var
          fail 'Crazy error' if !(start_object || @query_proxy)

          if start_object
            :"#{start_object.class.name.gsub('::', '_').downcase}#{start_object.neo_id}"
          else
            @query_proxy.node_var || :"node#{_chain_level}"
          end
        end

        def _association_query_start(var)
          # TODO: Better error
          fail 'Crazy error' if !(object = (start_object || @query_proxy))

          object.query_as(var)
        end

        def _rel_chain_var
          :"rel#{_chain_level - 1}"
        end

        attr_writer :context

        private

        def instance_vars_from_options!(options)
          @node_var, @source_object, @starting_query, @optional,
              @start_object, @query_proxy, @chain_level, @association_labels,
              @rel_length = options.values_at(:node, :source_object, :starting_query, :optional,
                                              :start_object, :query_proxy, :chain_level, :association_labels, :rel_length)
        end

        def build_deeper_query_proxy(method, args)
          new_link.tap do |new_query_proxy|
            Link.for_args(@model, method, args, association).each { |link| new_query_proxy._add_links(link) }
          end
        end
      end
    end
  end
end
