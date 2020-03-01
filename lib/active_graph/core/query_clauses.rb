module ActiveGraph
  module Core
    module QueryClauses
      class ArgError < StandardError
        attr_reader :arg_part
        def initialize(arg_part = nil)
          super
          @arg_part = arg_part
        end
      end

      class Clause
        UNDERSCORE = '_'
        COMMA_SPACE = ', '
        AND = ' AND '
        PRETTY_NEW_LINE = "\n  "

        attr_accessor :params, :arg
        attr_reader :options, :param_vars_added

        def initialize(arg, params, options = {})
          @arg = arg
          @options = options
          @params = params
          @param_vars_added = []
        end

        def value
          return @value if @value

          [String, Symbol, Integer, Hash, NilClass].each do |arg_class|
            from_method = "from_#{arg_class.name.downcase}"
            return @value = send(from_method, @arg) if @arg.is_a?(arg_class) && respond_to?(from_method)
          end

          fail ArgError
        rescue ArgError => arg_error
          message = "Invalid argument for #{self.class.keyword}.  Full arguments: #{@arg.inspect}"
          message += " | Invalid part: #{arg_error.arg_part.inspect}" if arg_error.arg_part

          raise ArgumentError, message
        end

        def from_hash(value)
          fail ArgError if !respond_to?(:from_key_and_value)

          value.map do |k, v|
            from_key_and_value k, v
          end
        end

        def from_string(value)
          value
        end

        def node_from_key_and_value(key, value, options = {})
          prefer = options[:prefer] || :var
          var = var_from_key_and_value(key, value, prefer)
          label = label_from_key_and_value(key, value, prefer)

          attributes = attributes_from_key_and_value(key, value)

          prefix_value = value
          if value.is_a?(Hash)
            prefix_value = (value.keys.join(UNDERSCORE) if value.values.any? { |v| v.is_a?(Hash) })
          end

          prefix_array = [key, prefix_value].tap(&:compact!).join(UNDERSCORE)
          formatted_attributes = attributes_string(attributes, "#{prefix_array}#{UNDERSCORE}")
          "(#{var}#{format_label(label)}#{formatted_attributes})"
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

          def from_arg(arg, params, options = {})
            new(arg, params, options) if !arg.respond_to?(:empty?) || !arg.empty?
          end

          def to_cypher(clauses, pretty = false)
            string = clause_string(clauses, pretty)

            final_keyword = if pretty
                              "#{clause_color}#{keyword}#{ANSI::CLEAR}"
                            else
                              keyword
                            end

            "#{final_keyword} #{string}" if !string.empty?
          end

          def clause_string(clauses, pretty)
            join_string = pretty ? clause_join + PRETTY_NEW_LINE : clause_join

            strings = clause_strings(clauses)
            stripped_string = strings.join(join_string).strip
            pretty && strings.size > 1 ? PRETTY_NEW_LINE + stripped_string : stripped_string
          end

          def clause_join
            ''
          end

          def clause_color
            ANSI::CYAN
          end

          def from_key_and_single_value(key, value)
            value.to_sym == :neo_id ? "ID(#{key})" : "#{key}.#{value}"
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

        def key_value_string(key, value, previous_keys = [], is_set = false)
          param = (previous_keys << key).join(UNDERSCORE)
          self.class.paramaterize_key!(param)

          if value.is_a?(Range)
            range_key_value_string(key, value, previous_keys, param)
          else
            value = value.first if array_value?(value, is_set) && value.size == 1

            param = add_param(param, value)

            "#{key} #{array_value?(value, is_set) ? 'IN' : '='} $#{param}"
          end
        end

        def range_key_value_string(key, value, previous_keys, param)
          begin_param, end_param = add_params("#{param}_range_min" => value.begin, "#{param}_range_max" => value.end)
          "#{key} >= $#{begin_param} AND #{previous_keys[-2]}.#{key} <#{'=' unless value.exclude_end?} $#{end_param}"
        end

        def array_value?(value, is_set)
          value.is_a?(Array) && !is_set
        end

        def format_label(label_arg)
          return label_arg.map { |arg| format_label(arg) }.join if label_arg.is_a?(Array)

          label_arg = label_arg.to_s.strip
          if !label_arg.empty? && label_arg[0] != ':'
            label_arg = "`#{label_arg}`" unless label_arg[' ']
            label_arg = ":#{label_arg}"
          end
          label_arg
        end

        def attributes_string(attributes, prefix = '')
          return '' if not attributes

          attributes_string = attributes.map do |key, value|
            if value.to_s =~ /^{.+}$/
              "#{key}: #{value}"
            else
              param_key = "#{prefix}#{key}".gsub(/:+/, '_')
              param_key = add_param(param_key, value)
              "#{key}: $#{param_key}"
            end
          end.join(Clause::COMMA_SPACE)

          " {#{attributes_string}}"
        end
      end

      class StartClause < Clause
        KEYWORD = 'START'

        def from_symbol(value)
          from_string(value.to_s)
        end

        def from_key_and_value(key, value)
          case value
          when String, Symbol
            "#{key} = #{value}"
          else
            fail ArgError, value
          end
        end

        class << self
          def clause_strings(clauses)
            clauses.map!(&:value)
          end

          def clause_join
            Clause::COMMA_SPACE
          end
        end
      end

      class WhereClause < Clause
        KEYWORD = 'WHERE'

        PAREN_SURROUND_REGEX = /^\s*\(.+\)\s*$/

        def from_key_and_value(key, value, previous_keys = [])
          case value
          when Hash then hash_key_value_string(key, value, previous_keys)
          when NilClass then "#{key} IS NULL"
          when Regexp then regexp_key_value_string(key, value, previous_keys)
          else
            key_value_string(key, value, previous_keys)
          end
        end

        class << self
          def clause_strings(clauses)
            clauses.flat_map do |clause|
              Array(clause.value).map do |v|
                (clause.options[:not] ? 'NOT' : '') + (v.to_s.match(PAREN_SURROUND_REGEX) ? v.to_s : "(#{v})")
              end
            end
          end

          def clause_join
            Clause::AND
          end
        end

        private

        def hash_key_value_string(key, value, previous_keys)
          value.map do |k, v|
            if k.to_sym == :neo_id
              v = Array(v).map { |item| (item.respond_to?(:neo_id) ? item.neo_id : item).to_i }
              key_value_string("ID(#{key})", v)
            else
              "#{key}.#{from_key_and_value(k, v, previous_keys + [key])}"
            end
          end.join(AND)
        end

        def regexp_key_value_string(key, value, previous_keys)
          pattern = (value.casefold? ? '(?i)' : '') + value.source

          param = [previous_keys + [key]].join(UNDERSCORE)
          self.class.paramaterize_key!(param)

          param = add_param(param, pattern)

          "#{key} =~ $#{param}"
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
        end
      end

      class CallClause < Clause
        KEYWORD = 'CALL'

        def from_string(value)
          value
        end

        class << self
          def clause_strings(clauses)
            clauses.map!(&:value)
          end

          def clause_join
            " #{KEYWORD} "
          end
        end
      end

      class MatchClause < Clause
        KEYWORD = 'MATCH'

        def from_symbol(value)
          '(' + from_string(value.to_s) + ')'
        end

        def from_key_and_value(key, value)
          node_from_key_and_value(key, value)
        end

        class << self
          def clause_strings(clauses)
            clauses.map!(&:value)
          end

          def clause_join
            Clause::COMMA_SPACE
          end
        end
      end

      class OptionalMatchClause < MatchClause
        KEYWORD = 'OPTIONAL MATCH'
      end

      class WithClause < Clause
        KEYWORD = 'WITH'

        def from_symbol(value)
          from_string(value.to_s)
        end

        def from_key_and_value(key, value)
          "#{value} AS #{key}"
        end

        class << self
          def clause_strings(clauses)
            clauses.map!(&:value)
          end

          def clause_join
            Clause::COMMA_SPACE
          end
        end
      end

      class WithDistinctClause < WithClause
        KEYWORD = 'WITH DISTINCT'
      end

      class UsingClause < Clause
        KEYWORD = 'USING'

        class << self
          def clause_strings(clauses)
            clauses.map!(&:value)
          end

          def clause_join
            " #{keyword} "
          end
        end
      end

      class CreateClause < Clause
        KEYWORD = 'CREATE'

        def from_string(value)
          value
        end

        def from_symbol(value)
          "(:#{value})"
        end

        def from_hash(hash)
          if hash.values.any? { |value| value.is_a?(Hash) }
            hash.map do |key, value|
              from_key_and_value(key, value)
            end
          else
            "(#{attributes_string(hash)})"
          end
        end

        def from_key_and_value(key, value)
          node_from_key_and_value(key, value, prefer: :label)
        end

        class << self
          def clause_strings(clauses)
            clauses.map!(&:value)
          end

          def clause_join
            ', '
          end

          def clause_color
            ANSI::GREEN
          end
        end
      end

      class CreateUniqueClause < CreateClause
        KEYWORD = 'MERGE'
      end

      class MergeClause < CreateClause
        KEYWORD = 'MERGE'

        class << self
          def clause_color
            ANSI::MAGENTA
          end

          def clause_join
            ' MERGE '
          end
        end
      end

      class DeleteClause < Clause
        KEYWORD = 'DELETE'

        def from_symbol(value)
          from_string(value.to_s)
        end

        class << self
          def clause_strings(clauses)
            clauses.map!(&:value)
          end

          def clause_join
            Clause::COMMA_SPACE
          end

          def clause_color
            ANSI::RED
          end
        end
      end

      class DetachDeleteClause < DeleteClause
        KEYWORD = 'DETACH DELETE'
      end

      class OrderClause < Clause
        KEYWORD = 'ORDER BY'

        def from_symbol(value)
          from_string(value.to_s)
        end

        def from_key_and_value(key, value)
          case value
          when String, Symbol
            self.class.from_key_and_single_value(key, value)
          when Array
            value.map do |v|
              v.is_a?(Hash) ? from_key_and_value(key, v) : self.class.from_key_and_single_value(key, v)
            end
          when Hash
            value.map { |k, v| "#{self.class.from_key_and_single_value(key, k)} #{v.upcase}" }
          end
        end

        class << self
          def clause_strings(clauses)
            clauses.map!(&:value)
          end

          def clause_join
            Clause::COMMA_SPACE
          end
        end
      end

      class LimitClause < Clause
        KEYWORD = 'LIMIT'

        def from_string(value)
          param_var = "#{self.class.keyword_downcase}_#{value}"
          param_var = add_param(param_var, value.to_i)
          "$#{param_var}"
        end

        def from_integer(value)
          from_string(value)
        end

        def from_nilclass(_value)
          ''
        end

        class << self
          def clause_strings(clauses)
            result_clause = clauses.last

            clauses[0..-2].map(&:param_vars_added).flatten.grep(/^limit_\d+$/).each do |var|
              result_clause.params.remove_param(var)
            end

            [result_clause.value]
          end
        end
      end

      class SkipClause < Clause
        KEYWORD = 'SKIP'

        def from_string(value)
          clause_id = "#{self.class.keyword_downcase}_#{value}"
          clause_id = add_param(clause_id, value.to_i)
          "$#{clause_id}"
        end

        def from_integer(value)
          clause_id = "#{self.class.keyword_downcase}_#{value}"
          clause_id = add_param(clause_id, value)
          "$#{clause_id}"
        end

        class << self
          def clause_strings(clauses)
            result_clause = clauses.last

            clauses[0..-2].map(&:param_vars_added).flatten.grep(/^skip_\d+$/).each do |var|
              result_clause.params.remove_param(var)
            end

            [result_clause.value]
          end
        end
      end

      class SetClause < Clause
        KEYWORD = 'SET'

        def from_key_and_value(key, value)
          case value
          when String, Symbol then "#{key}:`#{value}`"
          when Hash
            if @options[:set_props]
              param = add_param("#{key}_set_props", value)
              "#{key} = $#{param}"
            else
              value.map { |k, v| key_value_string("#{key}.`#{k}`", v, ['setter'], true) }
            end
          when Array then value.map { |v| from_key_and_value(key, v) }
          when NilClass then []
          else
            fail ArgError, value
          end
        end

        class << self
          def clause_strings(clauses)
            clauses.map!(&:value)
          end

          def clause_join
            Clause::COMMA_SPACE
          end

          def clause_color
            ANSI::YELLOW
          end
        end
      end

      class OnCreateSetClause < SetClause
        KEYWORD = 'ON CREATE SET'

        def initialize(*args)
          super
          @options[:set_props] = false
        end
      end

      class OnMatchSetClause < OnCreateSetClause
        KEYWORD = 'ON MATCH SET'
      end

      class RemoveClause < Clause
        KEYWORD = 'REMOVE'

        def from_key_and_value(key, value)
          case value
          when /^:/
            "#{key}:`#{value[1..-1]}`"
          when String
            "#{key}.#{value}"
          when Symbol
            "#{key}:`#{value}`"
          when Array
            value.map do |v|
              from_key_and_value(key, v)
            end
          else
            fail ArgError, value
          end
        end

        class << self
          def clause_strings(clauses)
            clauses.map!(&:value)
          end

          def clause_join
            Clause::COMMA_SPACE
          end
        end
      end

      class UnwindClause < Clause
        KEYWORD = 'UNWIND'

        def from_key_and_value(key, value)
          case value
          when String, Symbol
            "#{value} AS #{key}"
          when Array
            "#{value.inspect} AS #{key}"
          else
            fail ArgError, value
          end
        end

        class << self
          def clause_strings(clauses)
            clauses.map!(&:value)
          end

          def clause_join
            ' UNWIND '
          end
        end
      end

      class ReturnClause < Clause
        KEYWORD = 'RETURN'

        def from_symbol(value)
          from_string(value.to_s)
        end

        def from_key_and_value(key, value)
          case value
          when Array
            value.map do |v|
              from_key_and_value(key, v)
            end.join(Clause::COMMA_SPACE)
          when String, Symbol
            self.class.from_key_and_single_value(key, value)
          else
            fail ArgError, value
          end
        end

        class << self
          def clause_strings(clauses)
            clauses.map!(&:value)
          end

          def clause_join
            Clause::COMMA_SPACE
          end
        end
      end
    end
  end
end
