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
        attr_reader :caller, :association, :model, :starting_query

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
        # * caller:  The node instance at the start of the QueryProxy chain
        # * query_proxy: An existing QueryProxy chain upon which this new object should be built
        #
        # QueryProxy objects are evaluated lazily.
        def initialize(model, association = nil, options = {})
          @model = model
          @association = association
          @context = options.delete(:context)
          @options = options

          @node_var, @session, @caller, @starting_query, @optional = options.values_at(:node, :session, :caller, :starting_query, :optional)
          @rel_var = options[:rel] || _rel_chain_var

          @chain = []
          @params = options[:query_proxy] ? options[:query_proxy].instance_variable_get('@params') : {}
        end

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
          self.dup.tap do |new_query|
            new_query._add_params(params)
          end
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
          @chain.inject(base_query(var).params(@params)) do |query, (method, arg)|
            query.send(method, arg.respond_to?(:call) ? arg.call(var) : arg)
          end
        end

        def base_query(var)
          if @association
            chain_var = _association_chain_var
            (_association_query_start(chain_var) & _query).send(_match_type,
                                                                "#{chain_var}#{_association_arrow}(#{var}#{_model_label_string})")
          else
            starting_query ? (starting_query & _query_model_as(var)) : _query_model_as(var)
          end
        end

        def _model_label_string
          @model && ":`#{@model.mapped_label_name}`"
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
          module_eval(%{
            def #{method}(*args)
              build_deeper_query_proxy(:#{method}, args)
            end}, __FILE__, __LINE__)
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

          fail ArgumentError, "Node must be of the association's class when model is specified" if @model && other_nodes.any? { |other_node| !other_node.is_a?(@model) }

          start_object = @options[:start_object]

          other_nodes.each do |other_node|
            # Neo4j::Transaction.run do
            other_node.save unless other_node.neo_id

            return false if @association.perform_callback(start_object, other_node, :before) == false

            start_object.clear_association_cache

            _create_relationship(start_object, other_node, properties)

            @association.perform_callback(start_object, other_node, :after)
            # end
          end
        end

        def _nodeify(*args)
          [args].flatten.map do |arg|
            (arg.is_a?(Integer) || arg.is_a?(String)) ? @model.find(arg) : arg
          end.compact
        end

        def _create_relationship(start_object, other_node, properties)
          _session.query(context: @options[:context])
            .match(:start, :end)
            .where(start: {neo_id: start_object.neo_id}, end: {neo_id: other_node.neo_id})
            .send(create_method, "start#{_association_arrow(properties, true)}end").exec
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

        def optional?
          @optional == true
        end

        attr_reader :context

        protected

        # Methods are underscored to prevent conflict with user class methods

        def _add_params(params)
          @params = @params.merge(params)
        end

        def _add_links(links)
          @chain += links
        end

        def _query_model_as(var)
          match_arg = if @model
                        label = @model.respond_to?(:mapped_label_name) ? @model.mapped_label_name : @model
                        {var => label}
                      else
                        var
                      end
          _query.send(_match_type, match_arg)
        end

        def _query
          _session.query(context: @context)
        end

        # TODO: Refactor this. Too much happening here.
        def _result_string
          if self.association
            "result_#{self.association.name}".to_sym
          elsif self.model && self.model.name
            label = "result_#{self.model.name}"
            label.downcase!.tr!(':', '')
            label.to_sym
          else
            :result
          end
        end

        def _session
          @session || (@model && @model.neo4j_session)
        end

        def _association_arrow(properties = {}, create = false)
          @association && @association.arrow_cypher(@rel_var, properties, create)
        end

        def _chain_level
          (query_proxy = @options[:query_proxy]) ? (query_proxy._chain_level + 1) : 1
        end

        def _association_chain_var
          if start_object = @options[:start_object]
            :"#{start_object.class.name.gsub('::', '_').downcase}#{start_object.neo_id}"
          elsif query_proxy = @options[:query_proxy]
            query_proxy.node_var || :"node#{_chain_level}"
          else
            fail 'Crazy error' # TODO: Better error
          end
        end

        def _association_query_start(var)
          if start_object = @options[:start_object]
            start_object.query_as(var)
          elsif query_proxy = @options[:query_proxy]
            query_proxy.query_as(var)
          else
            fail 'Crazy error' # TODO: Better error
          end
        end

        def _rel_chain_var
          :"rel#{_chain_level - 1}"
        end

        def _match_type
          @optional ? :optional_match : :match
        end

        attr_writer :context

        private

        def create_method
          association.unique? ? :create_unique : :create
        end

        def build_deeper_query_proxy(method, args)
          self.dup.tap do |new_query|
            args.each do |arg|
              new_query._add_links(links_for_arg(method, arg))
            end
          end
        end

        def links_for_arg(method, arg)
          method_to_call = "links_for_#{method}_arg"

          default = [[method, arg]]

          self.send(method_to_call, arg) || default
        rescue NoMethodError
          default
        end

        def links_for_where_arg(arg)
          node_num = 1
          result = []
          if arg.is_a?(Hash)
            arg.each do |key, value|
              if @model && @model.association?(key)
                result += links_for_association(key, value, "n#{node_num}")

                node_num += 1
              else
                result << [:where, ->(v) { {v => {key => value}} }]
              end
            end
          elsif arg.is_a?(String)
            result << [:where, arg]
          end
          result
        end
        alias_method :links_for_node_where_arg, :links_for_where_arg

        def links_for_association(name, value, n_string)
          neo_id = value.try(:neo_id) || value
          fail ArgumentError, "Invalid value for '#{name}' condition" if not neo_id.is_a?(Integer)

          dir = @model.associations[name].direction

          arrow = dir == :out ? '-->' : '<--'
          [
            [:match, ->(v) { "#{v}#{arrow}(#{n_string})" }],
            [:where, ->(_) { {"ID(#{n_string})" => neo_id.to_i} }]
          ]
        end

        # We don't accept strings here. If you want to use a string, just use where.
        def links_for_rel_where_arg(arg)
          arg.each_with_object([]) do |(key, value), result|
            result << [:where, ->(_) { {rel_var => {key => value}} }]
          end
        end

        def links_for_order_arg(arg)
          [[:order, ->(v) { arg.is_a?(String) ? arg : {v => arg} }]]
        end

        def match_label(node)
          if node.class.respond_to?(:mapped_label_name)
            node.class.mapped_label_name
          elsif node.respond_to?(:labels)
            node.labels.first
          else
            ''
          end
        end

        def match_string(node)
          ":`#{node.class.mapped_label_name}`" if node.class.respond_to?(:mapped_label_name)
        end
      end
    end
  end
end
