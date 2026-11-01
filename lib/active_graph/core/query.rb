module ActiveGraph
  module Core
    # Allows for generation of cypher queries via ruby method calls (inspired by ActiveRecord / arel syntax)
    #
    # Can be used to express cypher queries in ruby nicely, or to more easily generate queries programatically.
    #
    # Also, queries can be passed around an application to progressively build a query across different concerns
    #
    # See also the following link for full cypher language documentation:
    # http://docs.neo4j.org/chunked/milestone/cypher-query-lang.html
    class Query
      include ActiveGraph::Core::QueryClauses
      include ActiveGraph::Core::QueryFindInBatches
      include QueryExt
      DEFINED_CLAUSES = {}

      attr_accessor :clauses

      class Parameters
        def initialize(hash = nil)
          @parameters = (hash || {})
        end

        def to_hash
          @parameters
        end

        def copy
          self.class.new(@parameters.dup)
        end

        def add_param(key, value)
          free_param_key(key).tap do |k|
            @parameters[k.freeze] = value
          end
        end

        def remove_param(key)
          @parameters.delete(key.to_sym)
        end

        def add_params(params)
          params.map do |key, value|
            add_param(key, value)
          end
        end

        private

        def free_param_key(key)
          k = key.to_sym

          return k if !@parameters.key?(k)

          i = 2
          i += 1 while @parameters.key?("#{key}#{i}".to_sym)

          "#{key}#{i}".to_sym
        end
      end

      class << self
        attr_accessor :pretty_cypher
      end

      def initialize(options = {})
        @options = options
        @clauses = []
        @_params = {}
        @params = Parameters.new
      end

      def inspect
        "#<Query CYPHER: #{ANSI::YELLOW}#{to_cypher.inspect}#{ANSI::CLEAR}>"
      end

      # @method start *args
      # START clause
      # @return [Query]

      # @method match *args
      # MATCH clause
      # @return [Query]

      # @method optional_match *args
      # OPTIONAL MATCH clause
      # @return [Query]

      # @method using *args
      # USING clause
      # @return [Query]

      # @method where *args
      # WHERE clause
      # @return [Query]

      # @method with *args
      # WITH clause
      # @return [Query]

      # @method with_distinct *args
      # WITH clause with DISTINCT specified
      # @return [Query]

      # @method order *args
      # ORDER BY clause
      # @return [Query]

      # @method limit *args
      # LIMIT clause
      # @return [Query]

      # @method skip *args
      # SKIP clause
      # @return [Query]

      # @method set *args
      # SET clause
      # @return [Query]

      # @method remove *args
      # REMOVE clause
      # @return [Query]

      # @method unwind *args
      # UNWIND clause
      # @return [Query]

      # @method return *args
      # RETURN clause
      # @return [Query]

      # @method return_distinct *args
      # RETURN DISTINCT clause
      # @return [Query]

      # @method create *args
      # CREATE clause
      # @return [Query]

      # @method create_unique *args
      # CREATE UNIQUE clause
      # @return [Query]

      # @method merge *args
      # MERGE clause
      # @return [Query]

      # @method on_create_set *args
      # ON CREATE SET clause
      # @return [Query]

      # @method on_match_set *args
      # ON MATCH SET clause
      # @return [Query]

      # @method delete *args
      # DELETE clause
      # @return [Query]

      # @method detach_delete *args
      # DETACH DELETE clause
      # @return [Query]

      METHODS = %w[start match optional_match call using where create create_unique merge set on_create_set on_match_set remove unwind delete detach_delete with with_distinct return return_distinct order skip limit union call_subquery_start call_subquery_end] # rubocop:disable Layout/LineLength
      BREAK_METHODS = %w(with with_distinct call call_subquery_start call_subquery_end)

      CLAUSIFY_CLAUSE = proc { |method| const_get(method.to_s.split('_').map(&:capitalize).join + 'Clause') }
      CLAUSES = METHODS.map(&CLAUSIFY_CLAUSE)

      METHODS.each_with_index do |clause, i|
        clause_class = CLAUSES[i]

        DEFINED_CLAUSES[clause.to_sym] = clause_class
        define_method(clause) do |*args|
          result = build_deeper_query(clause_class, args)

          BREAK_METHODS.include?(clause) ? result.break : result
        end
      end

      alias offset skip
      alias order_by order

      # Clears out previous order clauses and allows only for those specified by args
      def reorder(*args)
        query = copy

        query.remove_clause_class(OrderClause)
        query.order(*args)
      end

      # Works the same as the #where method, but the clause is surrounded by a
      # Cypher NOT() function
      def where_not(*args)
        build_deeper_query(WhereClause, args, not: true)
      end

      # Works the same as the #set method, but when given a nested array it will set properties rather than setting entire objects
      # @example
      #    # Creates a query representing the cypher: MATCH (n:Person) SET n.age = 19
      #    Query.new.match(n: :Person).set_props(n: {age: 19})
      def set_props(*args) # rubocop:disable Naming/AccessorMethodName
        build_deeper_query(SetClause, args, set_props: true)
      end

      # Allows what's been built of the query so far to be frozen and the rest built anew.  Can be called multiple times in a string of method calls
      # @example
      #   # Creates a query representing the cypher: MATCH (q:Person), r:Car MATCH (p: Person)-->q
      #   Query.new.match(q: Person).match('r:Car').break.match('(p: Person)-->q')
      def break
        build_deeper_query(nil)
      end

      # Allows for the specification of values for params specified in query
      # @example
      #   # Creates a query representing the cypher: MATCH (q: Person {id: $id})
      #   # Calls to params don't affect the cypher query generated, but the params will be
      #   # Passed down when the query is made
      #   Query.new.match('(q: Person {id: $id})').params(id: 12)
      #
      def params(args)
        copy.tap { |new_query| new_query.instance_variable_get('@params'.freeze).add_params(args) }
      end

      def unwrapped
        @_unwrapped_obj = true
        self
      end

      def unwrapped?
        !!@_unwrapped_obj
      end

      def response
        return @response if @response

        @response = ActiveGraph::Base.query(self, wrap: !unwrapped?)
      end

      def raise_if_cypher_error!(response)
        response.raise_cypher_error if response.respond_to?(:error?) && response.error?
      end

      def match_nodes(hash, optional_match = false)
        hash.inject(self) do |query, (variable, node_object)|
          neo_id = (node_object.respond_to?(:neo_id) ? node_object.neo_id : node_object)

          match_method = optional_match ? :optional_match : :match
          query.send(match_method, variable).where(variable => { neo_id: })
        end
      end

      def optional_match_nodes(hash)
        match_nodes(hash, true)
      end

      include Enumerable

      def count(var = nil)
        counted = var.nil? ? CypherDSL::Cypher.asterisk : QueryClauses::Fragments.name_or_raw(var)
        pluck(CypherDSL::Cypher.count(counted)).first
      end

      def each
        response.each { |object| yield object }
      end

      # @method to_a
      # Class is Enumerable.  Each yield is a Hash with the key matching the variable returned and the value being the value for that key from the response
      # @return [Array]
      # @raise [ActiveGraph::Server::CypherResponse::ResponseError] Raises errors from neo4j server

      # Executes a query without returning the result
      # @return [Boolean] true if successful
      # @raise [ActiveGraph::Server::CypherResponse::ResponseError] Raises errors from neo4j server
      def exec
        response

        true
      end

      # Return the specified columns as an array.
      # If one column is specified, a one-dimensional array is returned with the values of that column
      # If two columns are specified, a n-dimensional array is returned with the values of those columns
      #
      # @example
      #    Query.new.match(n: :Person).return(p: :name}.pluck(p: :name) # => Array of names
      # @example
      #    Query.new.match(n: :Person).return(p: :name}.pluck('p, DISTINCT p.name') # => Array of [node, name] pairs
      #
      def pluck(*columns)
        fail ArgumentError, 'No columns specified for Query#pluck' if columns.empty?

        column_values(return_query(columns))
      end

      # Like #pluck, with RETURN DISTINCT
      def pluck_distinct(*columns)
        fail ArgumentError, 'No columns specified for Query#pluck_distinct' if columns.empty?

        column_values(return_query(columns, distinct: true))
      end

      # The query with its RETURN clause replaced by one returning `columns`
      def return_query(columns, distinct: false)
        query = copy
        query.remove_clause_class(ReturnClause)

        distinct ? query.return_distinct(*columns) : query.return(*columns)
      end

      # The query as a cypher-dsl statement, or nil when no clause has been added yet.
      # Clauses of one part are applied in a fixed order (MATCH before WHERE before RETURN, …),
      # whatever the order they were called in.
      # @return [CypherDSL::Statement, nil]
      def statement
        return @statement if defined?(@statement)

        assembler = QueryClauses::Assembler.new
        partitioned_clauses.each do |clauses|
          clauses_by_class = clauses.group_by(&:class)
          CLAUSES.each do |clause_class|
            clause_class.apply(assembler, clauses_by_class[clause_class]) if clauses_by_class[clause_class]
          end
        end
        @statement = assembler.statement
      end

      RENDERER = CypherDSL::Renderer.default
      PRETTY_RENDERER = CypherDSL::Renderer.get_renderer(
        CypherDSL::Renderer::Configuration.new_config.with_pretty_print(true).always_escape_names(true).build
      )
      KEYWORD_COLORS = Hash.new(ANSI::CYAN).merge(
        'CREATE' => ANSI::GREEN, 'MERGE' => ANSI::MAGENTA,
        'SET' => ANSI::YELLOW, 'ON CREATE SET' => ANSI::YELLOW, 'ON MATCH SET' => ANSI::YELLOW,
        'DELETE' => ANSI::RED, 'DETACH DELETE' => ANSI::RED
      ).freeze
      KEYWORDS = /^(\s*)(OPTIONAL MATCH|MATCH|WHERE|WITH DISTINCT|WITH|RETURN DISTINCT|RETURN|ORDER BY|SKIP|LIMIT|CREATE|MERGE|ON CREATE SET|ON MATCH SET|SET|REMOVE|DETACH DELETE|DELETE|UNWIND|CALL|UNION ALL|UNION|USING|START|FOREACH|LOAD CSV)\b/ # rubocop:disable Layout/LineLength

      # Returns a CYPHER query string from the object query representation
      # @example
      #    Query.new.match(p: :Person).where(p: {age: 30})  # => "MATCH (p:`Person`) WHERE p.age = $p_age"
      #
      # @param [Hash] options `pretty: true` renders one clause per line with coloured keywords
      # @return [String] Resulting cypher query string
      def to_cypher(options = {})
        built = statement
        renderer = options[:pretty] ? PRETTY_RENDERER : RENDERER
        cypher_string = built ? renderer.render(built) : ''
        cypher_string = colorize(cypher_string) if options[:pretty]
        cypher_string = "CYPHER #{@options[:parser]} #{cypher_string}" if @options[:parser]
        cypher_string.strip
      end

      alias cypher to_cypher

      def pretty_cypher
        to_cypher(pretty: true)
      end

      def context
        @options[:context]
      end

      # The parameters registered by the clause arguments and by `params`, plus the values of
      # cypher-dsl parameters passed in directly (`where(n[:age].gt(Cypher.parameter(:min, 18)))`).
      def parameters
        dsl_parameters.merge(merge_params)
      end

      def partitioned_clauses
        @partitioned_clauses ||= PartitionedClauses.new(@clauses)
      end

      def print_cypher
        puts to_cypher(pretty: true).gsub(/\e[^m]+m/, '')
      end

      # Returns a CYPHER query specifying the union of the callee object's query and the argument's query
      #
      # @example
      #    # Generates cypher: MATCH (n:Person) UNION MATCH (o:Person) WHERE o.age = 10
      #    q = ActiveGraph::Core::Query.new.match(o: :Person).where(o: {age: 10})
      #    result = ActiveGraph::Core::Query.new.match(n: :Person).union_cypher(q)
      #
      # @param other [Query] Second half of UNION
      # @param options [Hash] Specify {all: true} to use UNION ALL
      # @return [String] Resulting UNION cypher query string
      def union_cypher(other, options = {})
        "#{to_cypher} UNION#{options[:all] ? ' ALL' : ''} #{other.to_cypher}"
      end

      def &(other)
        self.class.new.tap do |new_query|
          new_query.options = options.merge(other.options)
          new_query.clauses = clauses + other.clauses
        end.params(other._params)
      end

      def copy
        dup.tap do |query|
          query.instance_variable_set('@params'.freeze, @params.copy)
          query.instance_variable_set('@partitioned_clauses'.freeze, nil)
          query.remove_instance_variable('@statement') if query.instance_variable_defined?('@statement')
          query.instance_variable_set('@response'.freeze, nil)
        end
      end

      def clause?(method)
        clause_class = DEFINED_CLAUSES[method] || CLAUSIFY_CLAUSE.call(method)
        clauses.any? { |clause| clause.is_a?(clause_class) }
      end

      protected

      attr_accessor :options, :_params

      def add_clauses(clauses)
        @clauses += clauses
      end

      def remove_clause_class(clause_class)
        @clauses = @clauses.reject { |clause| clause.is_a?(clause_class) }
      end

      private

      # The values of the returned columns: a flat array for a single column, arrays of values otherwise.
      def column_values(query)
        columns = query.response.keys

        if columns.size == 1
          column = columns[0]
          query.map { |row| row[column] }
        else
          query.map { |row| columns.map { |column| row[column] } }
        end
      end

      # Values of the parameters the rendered statement carries. A name bound to two different
      # values (possible when queries built separately are merged with `&`) raises
      # CypherDSL::ConflictingParametersException instead of running a query with one of them.
      def dsl_parameters
        built = statement
        built ? built.parameters.transform_keys(&:to_sym) : {}
      end

      def colorize(cypher_string)
        cypher_string.gsub(KEYWORDS) { "#{Regexp.last_match(1)}#{KEYWORD_COLORS[Regexp.last_match(2)]}#{Regexp.last_match(2)}#{ANSI::CLEAR}" }
      end

      def build_deeper_query(clause_class, args = {}, options = {})
        copy.tap do |new_query|
          new_query.add_clauses [nil] if [nil, WithClause].include?(clause_class)
          new_query.add_clauses clause_class.from_args(args, new_query.instance_variable_get('@params'.freeze), options) if clause_class
        end
      end

      class PartitionedClauses
        def initialize(clauses)
          @clauses = clauses
          @partitioning = [[]]
        end

        include Enumerable

        def each
          generate_partitioning!

          @partitioning.each { |partition| yield partition }
        end

        def generate_partitioning!
          @partitioning = [[]]

          @clauses.each do |clause|
            if clause.nil? && !fresh_partition?
              @partitioning << []
            elsif clause_is_order_or_limit_directly_following_with_or_order?(clause)
              second_to_last << clause
            elsif clause_is_with_following_order_or_limit?(clause)
              second_to_last << clause
              second_to_last.sort_by! { |c| c.is_a?(::ActiveGraph::Core::QueryClauses::OrderClause) ? 1 : 0 }
            else
              @partitioning.last << clause
            end
          end
        end

        private

        def fresh_partition?
          @partitioning.last == []
        end

        def second_to_last
          @partitioning[-2]
        end

        def clause_is_order_or_limit_directly_following_with_or_order?(clause)
          self.class.clause_is_order_or_limit?(clause) &&
            @partitioning[-2] &&
            @partitioning[-1].empty? &&
            (@partitioning[-2].last.is_a?(::ActiveGraph::Core::QueryClauses::WithClause) ||
              @partitioning[-2].last.is_a?(::ActiveGraph::Core::QueryClauses::OrderClause))
        end

        def clause_is_with_following_order_or_limit?(clause)
          clause.is_a?(::ActiveGraph::Core::QueryClauses::WithClause) &&
            @partitioning[-2] && @partitioning[-2].any? { |c| self.class.clause_is_order_or_limit?(c) }
        end

        class << self
          def clause_is_order_or_limit?(clause)
            clause.is_a?(::ActiveGraph::Core::QueryClauses::OrderClause) ||
              clause.is_a?(::ActiveGraph::Core::QueryClauses::LimitClause)
          end
        end
      end

      # SHOULD BE DEPRECATED
      # Clauses merged in from other queries (see `&`) carry their own parameter registries.
      def merge_params
        clause_params = @clauses.compact.inject({}) { |params, clause| params.merge!(clause.params.to_hash) }
        @params.to_hash.merge(clause_params)
      end
    end
  end
end
