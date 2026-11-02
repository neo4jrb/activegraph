module ActiveGraph
  module Core
    # The clause classes behind ActiveGraph::Core::Query. Each class interprets the
    # arguments of one Query method (`match`, `where`, `return`, …) into cypher-dsl
    # objects (patterns, conditions, expressions, sort items, operations) and knows how
    # to add them to a CypherDSL::StatementBuilder. Strings are passed through verbatim
    # as raw fragments; cypher-dsl objects are accepted as they are.
    module QueryClauses
      class ArgError < StandardError
        attr_reader :arg_part
        def initialize(arg_part = nil)
          super
          @arg_part = arg_part
        end
      end

      # Shorthands for the cypher-dsl objects the clauses produce.
      module Fragments
        IDENTIFIER = /\A[A-Za-z_][A-Za-z0-9_]*\z/

        module_function

        # Verbatim Cypher text (no `$E` placeholder parsing).
        def raw(text)
          CypherDSL::RawExpression.new(text.to_s)
        end

        # Verbatim text interleaved with expressions, e.g. `raw_parts('WHERE ', condition)`.
        def raw_parts(*parts)
          CypherDSL::RawExpression.new(parts)
        end

        # `prefix item, item, …` as a raw fragment.
        def raw_list(prefix, items)
          raw_parts(prefix, *items.flat_map { |item| [item, ', '] }[0...-1])
        end

        def name(value)
          CypherDSL::SymbolicName.of(value)
        end

        # Plain identifiers become names, anything else (`n.prop`, `count(n)`) is raw Cypher.
        def name_or_raw(value)
          value.to_s.match?(IDENTIFIER) ? name(value) : raw(value)
        end

        # A WITH/UNWIND value: strings and symbols name variables, other values are literals.
        def expression(value)
          case value
          when CypherDSL::Expression then value
          when String then name_or_raw(value)
          when Symbol then name(value)
          else CypherDSL::Expression.coerce(value)
          end
        end

        def element_id(key)
          CypherDSL::FunctionInvocation.new('elementId', [name_or_raw(key)])
        end

        def property(key, value)
          CypherDSL::Cypher.property(name_or_raw(key), value)
        end

        # `key.value`, `elementId(key)` for `neo_id`, or raw text when `value` is not an identifier (`'name desc'`).
        def property_or_raw(key, value)
          return element_id(key) if value.to_s == 'neo_id'

          value.to_s.match?(IDENTIFIER) ? property(key, value) : raw("#{key}.#{value}")
        end

        def dsl_object?(object)
          object.class.name.to_s.start_with?('CypherDSL::')
        end
      end

      # Feeds interpreted clauses into a CypherDSL::StatementBuilder, remembering what
      # kind of clause came last so that WHERE, ORDER BY, SKIP and LIMIT can refine it.
      class Assembler
        attr_reader :builder

        def initialize
          @builder = CypherDSL::Statement.builder
          @last = nil
        end

        def empty?
          @last.nil?
        end

        # Appends a clause; `kind` is remembered for later refinement.
        def append(kind)
          @builder = yield(@builder)
          @last = kind
          self
        end

        # Refines the last clause if it is one of `kinds`; returns false otherwise.
        def refine(*kinds)
          return false unless kinds.include?(@last)

          @builder = yield(@builder)
          true
        end

        def raw_clause(expression)
          append(:raw) { |builder| builder.raw_clause(expression) }
        end

        def statement
          empty? ? nil : @builder.build
        end
      end

      class Clause
        include Fragments

        UNDERSCORE = '_'
        ARG_CLASSES = [String, Symbol, Integer, Hash, NilClass, Array, TrueClass, FalseClass].freeze

        attr_accessor :params, :arg
        attr_reader :options, :param_vars_added

        def initialize(arg, params, options = {})
          @arg = arg
          @options = options
          @params = params
          @param_vars_added = []
        end

        # The interpreted argument: a cypher-dsl object or an array of them.
        def value
          return @value if instance_variable_defined?(:@value)

          @value = interpret
        rescue ArgError => arg_error
          message = "Invalid argument for #{self.class.keyword}.  Full arguments: #{@arg.inspect}"
          message += " | Invalid part: #{arg_error.arg_part.inspect}" if arg_error.arg_part

          raise ArgumentError, message
        end

        def interpret
          return @arg if dsl_object?(@arg)

          ARG_CLASSES.each do |arg_class|
            from_method = "from_#{arg_class.name.downcase}"
            return send(from_method, @arg) if @arg.is_a?(arg_class) && respond_to?(from_method)
          end

          fail ArgError
        end

        def from_hash(value)
          fail ArgError if !respond_to?(:from_key_and_value)

          value.map do |k, v|
            from_key_and_value k, v
          end
        end

        def from_string(value)
          raw(value)
        end

        def node_from_key_and_value(key, value, options = {})
          prefer = options[:prefer] || :var
          var = var_from_key_and_value(key, value, prefer)
          labels = label_from_key_and_value(key, value, prefer)

          attributes = attributes_from_key_and_value(key, value)

          prefix_value = value
          if value.is_a?(Hash)
            prefix_value = (value.keys.join(UNDERSCORE) if value.values.any? { |v| v.is_a?(Hash) })
          end

          prefix_array = [key, prefix_value].tap(&:compact!).join(UNDERSCORE)
          node_pattern(var, labels, attributes_map(attributes, "#{prefix_array}#{UNDERSCORE}"))
        end

        def var_from_key_and_value(key, value, prefer = :var)
          case value
          when String, Symbol, Class, Module, NilClass, Array then key
          when Hash
            key if _use_key_for_var?(value, prefer)
          else
            fail ArgError, value
          end
        end

        def label_from_key_and_value(key, value, prefer = :var)
          case value
          when String, Symbol, Array, NilClass then value
          when Class, Module then value.name
          when Hash
            if value.values.map(&:class) == [Hash]
              value.first.first
            elsif !_use_key_for_var?(value, prefer)
              key
            end
          else
            fail ArgError, value
          end
        end

        def _use_key_for_var?(value, prefer)
          _nested_value_hash?(value) || prefer == :var
        end

        def _nested_value_hash?(value)
          value.values.any? { |v| v.is_a?(Hash) }
        end

        def attributes_from_key_and_value(_key, value)
          return nil unless value.is_a?(Hash)

          value.values.map(&:class) == [Hash] ? value.first[1] : value
        end

        class << self
          def keyword
            self::KEYWORD
          end

          def keyword_downcase
            keyword.downcase
          end

          def from_args(args, params, options = {})
            args.flatten!
            args.map { |arg| from_arg(arg, params, options) }.tap(&:compact!)
          end

          # Arguments are interpreted (and their parameters registered) right away.
          def from_arg(arg, params, options = {})
            new(arg, params, options).tap(&:value) if !arg.respond_to?(:empty?) || !arg.empty?
          end

          # Adds the clauses of one query part to the assembler.
          def apply(_assembler, _clauses)
            fail NotImplementedError, "#{self} cannot be applied"
          end

          # The interpreted values of all clauses as one flat list.
          def values(clauses)
            clauses.flat_map { |clause| [clause.value].flatten }.compact
          end

          # The Cypher text of `key.value` (`elementId(key)` for `neo_id`), for use in raw fragments.
          def from_key_and_single_value(key, value)
            value.to_sym == :neo_id ? "elementId(#{key})" : "#{key}.#{value}"
          end
        end

        def self.paramaterize_key!(key)
          key.tr_s!('^a-zA-Z0-9', UNDERSCORE)
          key.gsub!(/^_+|_+$/, '')
        end

        def add_param(key, value)
          @param_vars_added << key
          @params.add_param(key, value)
        end

        def add_params(keys_and_values)
          @param_vars_added += keys_and_values.keys
          @params.add_params(keys_and_values)
        end

        private

        # A registered parameter as a cypher-dsl parameter carrying its value.
        def parameter(key, value)
          CypherDSL::Cypher.parameter(add_param(key, value).to_s, value)
        end

        # The parameter name for a key path such as `[:q, :age]` or `['elementId(q)']`.
        def param_name(keys)
          param = keys.join(UNDERSCORE).dup
          self.class.paramaterize_key!(param)
          param
        end

        def array_value?(value)
          value.is_a?(Enumerable) && !value.is_a?(Hash)
        end

        # A node pattern as a raw fragment with its properties map embedded: labels given as Cypher
        # text (`':Person'`, `'Person {x: 1}'`) stay as they are, others are escaped. A raw fragment
        # rather than a cypher-dsl node, because the latter renders as `(n)` once a node of that name
        # has been rendered, whereas every hash pattern here spells out its own constraints.
        def node_pattern(var, labels, properties)
          labels = [labels].flatten.compact.map { |label| label.to_s.strip }.reject(&:empty?)
          raw_parts("(#{var}#{labels.map { |label| format_label(label) }.join}", *([' ', properties] if properties), ')')
        end

        def format_label(label)
          return label if label.start_with?(':')
          return ":#{label}" if label.include?(' ')

          ":#{CypherDSL::Renderer::Escaper.escape(label)}"
        end

        # `{key: $param, …}`; a value that already is a Cypher map literal (`'{a: 1}'`) stays as it is.
        def attributes_map(attributes, prefix = '')
          return nil if attributes.nil? || attributes.empty?

          entries = attributes.flat_map do |key, value|
            inline_map = value.to_s =~ /^{.+}$/
            [key.to_s, inline_map ? raw(value) : parameter("#{prefix}#{key}".gsub(/:+/, '_'), value)]
          end
          CypherDSL::Cypher.map_of(*entries)
        end
      end

      class StartClause < Clause
        KEYWORD = 'START'

        def from_string(value)
          value
        end

        def from_symbol(value)
          value.to_s
        end

        def from_key_and_value(key, value)
          case value
          when String, Symbol
            "#{key} = #{value}"
          else
            fail ArgError, value
          end
        end

        def self.apply(assembler, clauses)
          assembler.raw_clause(Fragments.raw("START #{values(clauses).join(', ')}"))
        end
      end

      class UnionClause < Clause
        KEYWORD = ''

        def from_array(args)
          "#{args[1]} RETURN #{args[0]} AS #{args.last}"
        end

        class << self
          def from_args(args, params, options = {})
            params.add_params(args[2])

            [from_arg(args, params, options)]
          end

          def apply(assembler, clauses)
            assembler.raw_clause(Fragments.raw(values(clauses).join(' UNION ')))
          end
        end
      end

      class WhereClause < Clause
        KEYWORD = 'WHERE'

        def from_string(value)
          raw(value).as_condition
        end

        def from_trueclass(_value)
          CypherDSL::Cypher.is_true
        end

        def from_falseclass(_value)
          CypherDSL::Cypher.is_false
        end

        def from_key_and_value(key, value, previous_keys = [])
          condition_for(name_or_raw(key), key, value, previous_keys)
        end

        class << self
          ARG_HAS_QUESTION_MARK_REGEX = /(^|\(|\s)\?(\s|\)|$)/

          def from_args(args, params, options = {})
            query_string, params_arg = args

            if query_string.is_a?(String) && (query_string.match(ARG_HAS_QUESTION_MARK_REGEX) || params_arg.is_a?(Hash))
              if params_arg.is_a?(Hash)
                params.add_params(params_arg)
              else
                param_var = params.add_params(question_mark_param: params_arg)[0]
                query_string = query_string.gsub(ARG_HAS_QUESTION_MARK_REGEX, "\\1$#{param_var}\\2")
              end

              [from_arg(query_string, params, options)]
            else
              super
            end
          end

          # All conditions of the part joined by AND, on the preceding MATCH or WITH.
          def apply(assembler, clauses)
            conditions = clauses.flat_map do |clause|
              [clause.value].flatten.compact.map { |condition| clause.options[:not] ? condition.not : condition }
            end
            return if conditions.empty?

            condition = conditions.inject { |all, one| all.and(one) }
            assembler.refine(:match, :with) { |builder| builder.where(condition) } ||
              assembler.raw_clause(Fragments.raw_parts('WHERE ', condition))
          end
        end

        private

        def condition_for(lhs, key, value, previous_keys)
          case value
          when Hash then hash_conditions(lhs, key, value, previous_keys)
          when NilClass then lhs.is_null
          when Regexp then lhs.matches(parameter(param_name(previous_keys + [key]), regexp_pattern(value)))
          when Range then range_condition(lhs, param_name(previous_keys + [key]), value)
          else
            value = value.first if array_value?(value) && value.size == 1
            param = parameter(param_name(previous_keys + [key]), value)
            array_value?(value) ? lhs.in(param) : lhs.is_equal_to(param)
          end
        end

        def hash_conditions(container, key, hash, previous_keys)
          hash.map do |k, v|
            if k.to_sym == :neo_id
              v = Array(v).map { |item| item.respond_to?(:neo_id) ? item.neo_id : item }
              condition_for(element_id(key), "elementId(#{key})", v, [])
            else
              condition_for(property_of(container, k), k, v, previous_keys + [key])
            end
          end.inject { |all, one| all.and(one) }
        end

        def property_of(container, key)
          key.to_s.match?(IDENTIFIER) ? container.property(key) : raw_parts(container, ".#{key}")
        end

        def range_condition(lhs, base, range)
          min = parameter("#{base}_range_min", range.begin)
          max = parameter("#{base}_range_max", range.end)
          lhs.gte(min).and(range.exclude_end? ? lhs.lt(max) : lhs.lte(max))
        end

        def regexp_pattern(value)
          (value.casefold? ? '(?i)' : '') + value.source
        end
      end

      class CallClause < Clause
        KEYWORD = 'CALL'

        def from_string(value)
          value
        end

        def self.apply(assembler, clauses)
          values(clauses).each { |value| assembler.raw_clause(Fragments.raw("CALL #{value}")) }
        end
      end

      class CallSubqueryStartClause < Clause
        KEYWORD = 'CALL {'

        def from_nilclass(_value)
          nil
        end

        def from_string(value)
          value
        end

        def self.apply(assembler, clauses)
          clauses.each do |clause|
            assembler.raw_clause(Fragments.raw([KEYWORD, clause.value.to_s.strip].reject(&:empty?).join(' ')))
          end
        end
      end

      class CallSubqueryEndClause < Clause
        KEYWORD = '}'

        def from_nilclass(_value)
          nil
        end

        def self.apply(assembler, clauses)
          clauses.each { assembler.raw_clause(Fragments.raw(KEYWORD)) }
        end
      end

      class MatchClause < Clause
        KEYWORD = 'MATCH'

        def from_symbol(value)
          CypherDSL::Cypher.any_node(value)
        end

        def from_key_and_value(key, value)
          node_from_key_and_value(key, value)
        end

        def self.apply(assembler, clauses)
          patterns = values(clauses)
          assembler.append(:match) { |builder| builder.match(*patterns) } unless patterns.empty?
        end
      end

      class OptionalMatchClause < MatchClause
        KEYWORD = 'OPTIONAL MATCH'

        def self.apply(assembler, clauses)
          patterns = values(clauses)
          assembler.append(:match) { |builder| builder.optional_match(*patterns) } unless patterns.empty?
        end
      end

      class WithClause < Clause
        KEYWORD = 'WITH'

        def from_symbol(value)
          name(value)
        end

        def from_string(value)
          name_or_raw(value)
        end

        def from_key_and_value(key, value)
          expression(value).as(key)
        end

        def self.apply(assembler, clauses)
          items = values(clauses)
          assembler.append(:with) { |builder| builder.with(*items) } unless items.empty?
        end
      end

      class WithDistinctClause < WithClause
        KEYWORD = 'WITH DISTINCT'

        def self.apply(assembler, clauses)
          items = values(clauses)
          assembler.append(:with) { |builder| builder.with_distinct(*items) } unless items.empty?
        end
      end

      class UsingClause < Clause
        KEYWORD = 'USING'

        def from_string(value)
          value
        end

        def self.apply(assembler, clauses)
          values(clauses).each { |value| assembler.raw_clause(Fragments.raw("USING #{value}")) }
        end
      end

      class CreateClause < Clause
        KEYWORD = 'CREATE'

        def from_symbol(value)
          CypherDSL::Cypher.node(value.to_s)
        end

        def from_hash(hash)
          if hash.values.any? { |value| value.is_a?(Hash) }
            hash.map do |key, value|
              from_key_and_value(key, value)
            end
          else
            CypherDSL::Cypher.any_node.with_properties(attributes_map(hash))
          end
        end

        def from_key_and_value(key, value)
          node_from_key_and_value(key, value, prefer: :label)
        end

        def self.apply(assembler, clauses)
          patterns = values(clauses)
          assembler.append(:create) { |builder| builder.create(*patterns) } unless patterns.empty?
        end
      end

      class CreateUniqueClause < CreateClause
        KEYWORD = 'MERGE'

        def self.apply(assembler, clauses)
          patterns = values(clauses)
          assembler.append(:merge) { |builder| builder.merge(*patterns) } unless patterns.empty?
        end
      end

      class MergeClause < CreateClause
        KEYWORD = 'MERGE'

        # Every pattern gets its own MERGE clause.
        def self.apply(assembler, clauses)
          values(clauses).each { |pattern| assembler.append(:merge) { |builder| builder.merge(pattern) } }
        end
      end

      class DeleteClause < Clause
        KEYWORD = 'DELETE'

        def from_symbol(value)
          name(value)
        end

        def from_string(value)
          name_or_raw(value)
        end

        def self.apply(assembler, clauses)
          items = values(clauses)
          assembler.append(:delete) { |builder| builder.delete(*items) } unless items.empty?
        end
      end

      class DetachDeleteClause < DeleteClause
        KEYWORD = 'DETACH DELETE'

        def self.apply(assembler, clauses)
          items = values(clauses)
          assembler.append(:delete) { |builder| builder.detach_delete(*items) } unless items.empty?
        end
      end

      class OrderClause < Clause
        KEYWORD = 'ORDER BY'

        def from_symbol(value)
          name(value)
        end

        def from_string(value)
          name_or_raw(value)
        end

        def from_key_and_value(key, value)
          case value
          when String, Symbol
            property_or_raw(key, value)
          when Array
            value.map do |v|
              v.is_a?(Hash) ? from_key_and_value(key, v) : property_or_raw(key, v)
            end
          when Hash
            value.map { |k, v| CypherDSL::Cypher.sort(property_or_raw(key, k), v.to_s.downcase.to_sym) }
          end
        end

        # ORDER BY belongs to the preceding RETURN or WITH; elsewhere it is emitted as is.
        def self.apply(assembler, clauses)
          items = values(clauses)
          return if items.empty? # e.g. `order(n: nil)` from QueryProxy#first on a model without id property

          assembler.refine(:return, :with) { |builder| builder.order_by(*items) } ||
            assembler.raw_clause(Fragments.raw_list('ORDER BY ', items))
        end
      end

      # Shared by LIMIT and SKIP, which stay unrelated classes because `Query#clause?(:limit)` and
      # `QueryProxy#limit_value` look for LimitClause instances.
      class PagingClause < Clause
        def from_string(value)
          from_integer(value.to_i)
        end

        def from_integer(value)
          parameter("#{self.class.keyword_downcase}_#{value}", value)
        end

        def from_nilclass(_value)
          nil
        end

        # The last LIMIT / SKIP wins, like in the previous string-based implementation.
        def self.apply(assembler, clauses)
          amount = clauses.last.value
          return if amount.nil?

          assembler.refine(:return, :with) { |builder| builder.send(keyword_downcase, amount) } ||
            assembler.raw_clause(Fragments.raw_parts("#{keyword} ", amount))
        end
      end

      class LimitClause < PagingClause
        KEYWORD = 'LIMIT'
      end

      class SkipClause < PagingClause
        KEYWORD = 'SKIP'
      end

      class SetClause < Clause
        KEYWORD = 'SET'

        def from_key_and_value(key, value)
          case value
          when String, Symbol then CypherDSL::Cypher.set_label(name(key), value.to_s)
          when Hash
            if @options[:set_props]
              CypherDSL::Cypher.set(name(key), parameter("#{key}_set_props", value))
            else
              value.map do |k, v|
                CypherDSL::Cypher.set(property(key, k), parameter(param_name(['setter', "#{key}.`#{k}`"]), v))
              end
            end
          when Array then value.map { |v| from_key_and_value(key, v) }
          when NilClass then []
          else
            fail ArgError, value
          end
        end

        def self.apply(assembler, clauses)
          operations = values(clauses)
          return if operations.empty?

          assembler.append(:set) { |builder| builder.set(*operations) }
        end
      end

      class OnCreateSetClause < SetClause
        KEYWORD = 'ON CREATE SET'
        ACTION = :on_create

        def initialize(*args)
          super
          @options[:set_props] = false
        end

        # Belongs to the preceding MERGE; elsewhere it is emitted as is.
        def self.apply(assembler, clauses)
          operations = values(clauses)
          return if operations.empty?

          assembler.refine(:merge) { |builder| builder.send(self::ACTION).set(*operations) } ||
            assembler.raw_clause(Fragments.raw_list("#{keyword} ", operations))
        end
      end

      class OnMatchSetClause < OnCreateSetClause
        KEYWORD = 'ON MATCH SET'
        ACTION = :on_match
      end

      class RemoveClause < Clause
        KEYWORD = 'REMOVE'

        def from_key_and_value(key, value)
          case value
          when /^:/
            CypherDSL::Cypher.remove_label(name(key), value[1..-1])
          when String
            property(key, value)
          when Symbol
            CypherDSL::Cypher.remove_label(name(key), value.to_s)
          when Array
            value.map do |v|
              from_key_and_value(key, v)
            end
          else
            fail ArgError, value
          end
        end

        def self.apply(assembler, clauses)
          items = values(clauses)
          assembler.append(:remove) { |builder| builder.remove(*items) } unless items.empty?
        end
      end

      class UnwindClause < Clause
        KEYWORD = 'UNWIND'

        def from_key_and_value(key, value)
          case value
          when String, Symbol
            [name_or_raw(value), key]
          when Array
            [CypherDSL::Cypher.literal_of(value), key]
          else
            fail ArgError, value
          end
        end

        # The pairs of a hash argument, or the raw fragment of a string argument.
        def self.values(clauses)
          clauses.flat_map { |clause| [clause.value].flatten(1) }.compact
        end

        # `[list, variable]` pairs become UNWIND clauses, a raw string is emitted as is.
        def self.apply(assembler, clauses)
          values(clauses).each do |value|
            if value.is_a?(Array)
              list, variable = value
              assembler.append(:unwind) { |builder| builder.unwind(list).as(variable) }
            else
              assembler.raw_clause(Fragments.raw_parts('UNWIND ', value))
            end
          end
        end
      end

      class ReturnClause < Clause
        KEYWORD = 'RETURN'

        def from_symbol(value)
          name(value)
        end

        def from_string(value)
          name_or_raw(value)
        end

        def from_key_and_value(key, value)
          case value
          when Array
            value.map do |v|
              from_key_and_value(key, v)
            end
          when String, Symbol
            property_or_raw(key, value)
          else
            fail ArgError, value
          end
        end

        # One projection; RETURN DISTINCT when any of the clauses came from `return_distinct`.
        def self.apply(assembler, clauses)
          items = values(clauses)
          return if items.empty?

          projection = clauses.any? { |clause| clause.options[:distinct] } ? :returning_distinct : :returning
          assembler.append(:return) { |builder| builder.send(projection, *items) }
        end
      end
    end
  end
end
