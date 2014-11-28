module Neo4j
  module ActiveNode
    module Query
      class QueryProxy

        include Enumerable
        include Neo4j::ActiveNode::Query::QueryProxyMethods
        include Neo4j::ActiveNode::Query::QueryProxyFindInBatches

        # The most recent node to start a QueryProxy chain.
        # Will be nil when using QueryProxy chains on class methods.
        attr_reader :caller, :association, :model

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
          @node_var = options[:node]
          @rel_var = options[:rel] || _rel_chain_var
          @session = options[:session]
          @caller = options[:caller]
          @chain = []
          @params = options[:query_proxy] ? options[:query_proxy].instance_variable_get('@params') : {}
        end

        # The current node identifier on deck, so to speak. It is the object that will be returned by calling `each` and the last node link
        # in the QueryProxy chain.
        def identity
          @node_var || :result
        end
        alias_method :node_identity, :identity

        # The relationship identifier most recently used by the QueryProxy chain.
        def rel_identity
          @rel_var
        end

        # Executes the query against the database if the results are not already present in a node's association cache. This method is
        # shared by <tt>each</tt>, <tt>each_rel</tt>, and <tt>each_with_rel</tt>.
        # @param [String,Symbol] node The string or symbol of the node to return from the database.
        # @param [String,Symbol] rel The string or symbol of a relationship to return from the database.
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

        # Just like every other <tt>each</tt> but it allows for optional params to support the versions that also return relationships.
        # The <tt>node</tt> and <tt>rel</tt> params are typically used by those other methods but there's nothing stopping you from
        # using `your_node.each(true, true)` instead of `your_node.each_with_rel`.
        # @return [Enumerable] An enumerable containing some combination of nodes and rels.
        def each(node = true, rel = nil, &block)
          if node && rel
            enumerable_query(identity, @rel_var).each { |obj, rel| yield obj, rel }
          else
            pluck_this = !rel ? identity : @rel_var
            enumerable_query(pluck_this).each { |obj| yield obj }
          end
        end

        # When called at the end of a QueryProxy chain, it will return the resultant relationship objects intead of nodes.
        # For example, to return the relationship between a given student and their lessons:
        #   student.lessons.each_rel do |rel|
        # @return [Enumerable] An enumerable containing any number of applicable relationship objects.
        def each_rel(&block)
          block_given? ? each(false, true, &block) : to_enum(:each, false, true)
        end

        # When called at the end of a QueryProxy chain, it will return the nodes and relationships of the last link.
        # For example, to return a lesson and each relationship to a given student:
        #   student.lessons.each_with_rel do |lesson, rel|
        def each_with_rel(&block)
          block_given? ? each(true, true, &block) : to_enum(:each, true, true)
        end

        # Does exactly what you would hope. Without it, comparing `bobby.lessons == sandy.lessons` would evaluate to false because it
        # would be comparing the QueryProxy objects, not the lessons themselves.
        def ==(value)
          self.to_a == value
        end

        METHODS = %w[where rel_where order skip limit]

        METHODS.each do |method|
          module_eval(%Q{
            def #{method}(*args)
              build_deeper_query_proxy(:#{method}, args)
            end}, __FILE__, __LINE__)
        end
        # Since there is a rel_where method, it seems only natural for there to be node_where
        alias_method :node_where, :where
        alias_method :offset, :skip
        alias_method :order_by, :order

        # For getting variables which have been defined as part of the association chain
        def pluck(*args)
          self.query.pluck(*args)
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
          query = if @association
            chain_var = _association_chain_var
            label_string = @model && ":`#{@model.mapped_label_name}`"
            (_association_query_start(chain_var) & _query_model_as(var)).match("#{chain_var}#{_association_arrow}(#{var}#{label_string})")
          else
            _query_model_as(var)
          end

          # Build a query chain via the chain, return the result
          @chain.inject(query.params(@params)) do |query, (method, arg)|
            query.send(method, arg.respond_to?(:call) ? arg.call(var) : arg)
          end
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



        # Cypher string for the QueryProxy's query. This will not include params. For the full output, see <tt>to_cypher_with_params</tt>.
        def to_cypher
          query.to_cypher
        end

        # Returns a string of the cypher query with return objects and params
        # @param [Array] columns array containing symbols of identifiers used in the query
        # @return [String]
        def to_cypher_with_params(columns = [:result])
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
          raise "Can only create associations on associations" unless @association
          other_nodes = [other_nodes].flatten
          properties = @association.inject_classname(properties)
          other_nodes = other_nodes.map do |other_node|
            case other_node
            when Integer, String
              @model.find(other_node)
            else
              other_node
            end
          end.compact

          raise ArgumentError, "Node must be of the association's class when model is specified" if @model && other_nodes.any? {|other_node| !other_node.is_a?(@model) }
          other_nodes.each do |other_node|
            #Neo4j::Transaction.run do
              other_node.save if not other_node.persisted?

              return false if @association.perform_callback(@options[:start_object], other_node, :before) == false

              start_object = @options[:start_object]
              start_object.clear_association_cache
              _session.query(context: @options[:context])
                .match("(start#{match_string(start_object)}), (end#{match_string(other_node)})").where("ID(start) = {start_id} AND ID(end) = {end_id}")
                .params(start_id: start_object.neo_id, end_id: other_node.neo_id)
                .create("start#{_association_arrow(properties, true)}end").exec

              @association.perform_callback(@options[:start_object], other_node, :after)
            #end
          end
        end

        # QueryProxy objects act as a representation of a model at the class level so we pass through calls
        # This allows us to define class functions for reusable query chaining or for end-of-query aggregation/summarizing
        def method_missing(method_name, *args, &block)
          if @model && @model.respond_to?(method_name)
            args[2] = self if @model.has_association?(method_name) || @model.has_scope?(method_name)
            scoping { @model.public_send(method_name, *args, &block) }
          else
            super
          end
        end

        attr_reader :context
        attr_reader :node_var

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
          _session.query(context: @context).match(match_arg)
        end

        def _session
          @session || (@model && @model.neo4j_session)
        end

        def _association_arrow(properties = {}, create = false)
          @association && @association.arrow_cypher(@rel_var, properties, create)
        end

        def _chain_level
          if @options[:start_object]
            1
          elsif query_proxy = @options[:query_proxy]
            query_proxy._chain_level + 1
          else
            1
          end
        end

        def _association_chain_var
          if start_object = @options[:start_object]
            :"#{start_object.class.name.gsub('::', '_').downcase}#{start_object.neo_id}"
          elsif query_proxy = @options[:query_proxy]
            query_proxy.node_var || :"node#{_chain_level}"
          else
            raise "Crazy error" # TODO: Better error
          end
        end

        def _association_query_start(var)
          if start_object = @options[:start_object]
            start_object.query_as(var)
          elsif query_proxy = @options[:query_proxy]
            query_proxy.query_as(var)
          else
            raise "Crazy error" # TODO: Better error
          end
        end

        def _rel_chain_var
          :"rel#{_chain_level - 1}"
        end

        attr_writer :context

        private

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
              if @model && @model.has_association?(key)

                neo_id = value.try(:neo_id) || value
                raise ArgumentError, "Invalid value for '#{key}' condition" if not neo_id.is_a?(Integer)

                n_string = "n#{node_num}"
                dir = @model.associations[key].direction

                arrow = dir == :out ? '-->' : '<--'
                result << [:match, ->(v) { "#{v}#{arrow}(#{n_string})" }]
                result << [:where, ->(v) { {"ID(#{n_string})" => neo_id.to_i} }]
                node_num += 1
              else
                result << [:where, ->(v) { {v => {key => value}}}]
              end
            end
          elsif arg.is_a?(String)
            result << [:where, arg]
          end
          result
        end
        alias_method :links_for_node_where_arg, :links_for_where_arg

        # We don't accept strings here. If you want to use a string, just use where.
        def links_for_rel_where_arg(arg)
          arg.each_with_object([]) do |(key, value), result|
            result << [:where, ->(v) {{ rel_identity => { key => value }}}]
          end
        end

        def links_for_order_arg(arg)
          [[:order, ->(v) { arg.is_a?(String) ? arg : {v => arg} }]]
        end

        def match_string(node)
          ":`#{node.class.mapped_label_name}`" if node.class.respond_to?(:mapped_label_name)
        end
      end
    end
  end
end

