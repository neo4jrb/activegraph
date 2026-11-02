module ActiveGraph
  module Node
    module Query
      class QueryProxy
        class Link
          OUTER_SUBQUERY_PREFIX = 'outer_'.freeze
          attr_reader :clause

          def initialize(clause, arg, args = [])
            @clause = clause
            @arg = arg
            @args = args
          end

          def args(var, rel_var)
            if @arg.respond_to?(:call)
              @arg.call(var, rel_var)
            else
              [@arg] + @args
            end
          end

          def start_of_subquery?
            clause == :call_subquery_start
          end

          def end_of_subquery?
            clause == :call_subquery_end
          end

          def subquery_var(original_var)
            return unless start_of_subquery?

            "#{OUTER_SUBQUERY_PREFIX}#{original_var}"
          end

          def update_outer_query_var(original_var)
            return original_var unless end_of_subquery?

            original_var.delete_prefix(OUTER_SUBQUERY_PREFIX)
          end

          class << self
            def for_clause(clause, arg, model, *args)
              method_to_call = "for_#{clause}_clause"
              return unless respond_to?(method_to_call)

              send(method_to_call, arg, model, *args)
            end

            def for_union_clause(arg, model, *args)
              links = []
              # The subquery imports the outer identity, which the continuation branches build on.
              links << new(:call_subquery_start, ->(var, _) { [var] }, *args)
              arg[:subquery_parts].each_with_index do |subquery_part, loop_index|
                links << init_union_link(arg[:proxy], model, subquery_part, loop_index, args)
              end
              links << new(:call_subquery_end, nil, *args)
              links << post_subquery_with_clause(arg[:first_clause], args)
            end

            def post_subquery_with_clause(first_clause, args)
              clause_arg_lambda = lambda do |v, _|
                if first_clause
                  [v]
                else
                  [v, "#{OUTER_SUBQUERY_PREFIX}#{v}"]
                end
              end

              new(:with, clause_arg_lambda, *args)
            end

            def init_union_link(proxy, model, subquery_part, loop_index, args)
              union_proc = if subquery_proxy_part = subquery_part.call rescue nil # rubocop:disable Style/RescueModifier
                             independent_union_subquery_proc(subquery_proxy_part, loop_index)
                           else
                             continuation_union_subquery_proc(proxy, model, subquery_part, loop_index)
                           end
              new(:union, union_proc, *args)
            end

            # Each union link yields `[builder, outer_identity]` for Core::Query#union: `builder.call(prefix)`
            # builds the branch with its parameters namespaced by `prefix` plus the branch's own
            # `<identity>_UNION<index>_`, so the names are unique by construction, also across nested unions.

            # A branch given as a complete proxy, `-> { Teacher.where(name: 'x') }`.
            def independent_union_subquery_proc(proxy, loop_index)
              lambda do |identity, _|
                builder = lambda do |enclosing_namespace|
                  namespace = union_namespace(enclosing_namespace, identity, loop_index)
                  [proxy.identity, proxy.query_as(proxy.identity, params_namespace: namespace)]
                end
                [builder, identity.delete_prefix(OUTER_SUBQUERY_PREFIX)]
              end
            end

            # A branch continuing the outer query, `-> { where(name: 'x') }`: the block runs against a proxy
            # that imports the outer identity (`WITH id WITH id`).
            def continuation_union_subquery_proc(outer_proxy, model, subquery_part, loop_index)
              lambda do |identity, _|
                builder = lambda do |enclosing_namespace|
                  namespace = union_namespace(enclosing_namespace, identity, loop_index)
                  importing = union_branch_start(outer_proxy.as(identity)).with(identity).with(identity)
                  start = importing.proxy_as(model, identity)
                  complete = start.instance_exec(&subquery_part) || start
                  [complete.identity, complete.query_as(complete.identity, params_namespace: namespace)]
                end
                [builder, identity.delete_prefix(OUTER_SUBQUERY_PREFIX)]
              end
            end

            def union_namespace(enclosing_namespace, identity, loop_index)
              "#{enclosing_namespace}#{identity}_UNION#{loop_index}_"
            end

            # The query a continuation branch starts from. The clauses before the union are rendered once,
            # before `CALL {`, so the branch starts empty; with nothing before the union the outer query is
            # empty instead and the proxy's own MATCH opens the branch.
            def union_branch_start(proxy)
              return proxy.query unless proxy.send(:chain).present? || proxy.starting_query

              proxy.send(:_query).tap { |query| query.proxy_chain_level = proxy.send(:_chain_level) }
            end

            def for_where_clause(arg, model, *args)
              node_num = 1
              result = []
              if arg.is_a?(Hash)
                arg.each do |key, value|
                  if model && model.association?(key)
                    result += for_association(key, value, "n#{node_num}", model)
                    node_num += 1
                  else
                    result << new_for_key_and_value(model, key, value)
                  end
                end
              elsif !arg.nil? # a Cypher string or a cypher-dsl condition
                result << new(:where, arg, args)
              end
              result
            end
            alias for_node_where_clause for_where_clause

            def for_where_not_clause(*args)
              for_where_clause(*args).each do |link|
                link.instance_variable_set('@clause', :where_not)
              end
            end

            def new_for_key_and_value(model, key, value)
              key = converted_key(model, key)

              val = if !model
                      value
                    elsif key == model.id_property_name
                      try_id(value)
                    else
                      converted_value(model, key, value)
                    end

              new(:where, ->(v, _) { {v => {key => val}} })
            end

            private def try_id(value)
              case value
              when Shared::Identity
                value.id
              when Enumerable
                value.map(&method(:try_id))
              else
                value
              end
            end

            def for_association(name, value, n_string, model)
              neo_id = value.try(:neo_id) || value
              fail ArgumentError, "Invalid value for '#{name}' condition" unless neo_id.is_a?(String)

              association = model.associations[name]
              other = CypherDSL::Cypher.any_node(n_string)
              [
                new(:match, ->(v, _) { association.relationship_pattern(CypherDSL::Cypher.any_node(v), other) }),
                new(:where, ->(_, _) { {n_string => {neo_id: neo_id}} })
              ]
            end

            # We don't accept strings here. If you want to use a string, just use where.
            def for_rel_where_clause(arg, _, association)
              arg.each_with_object([]) do |(key, value), result|
                rel_class = association.relationship_class if association.relationship_class
                val =  rel_class ? converted_value(rel_class, key, value) : value
                result << new(:where, ->(_, rel_var) { {rel_var => {key => val}} })
              end
            end

            def for_rel_where_not_clause(*args)
              for_rel_where_clause(*args).each do |link|
                link.instance_variable_set('@clause', :where_not)
              end
            end

            def for_rel_order_clause(arg, _)
              [new(:order, ->(_, v) { arg.is_a?(String) ? arg : {v => arg} })]
            end

            def for_order_clause(arg, model)
              [new(:order, ->(v, _) { arg.is_a?(String) ? arg : {v => converted_keys(model, arg)} })]
            end

            def for_args(model, clause, args, association = nil)
              if [:where, :where_not].include?(clause) && args[0].is_a?(String) # Better way?
                [for_arg(model, clause, args[0], *args[1..-1])]
              elsif [:rel_where, :rel_where_not].include?(clause)
                args.map { |arg| for_arg(model, clause, arg, association) }
              elsif clause == :union
                [for_arg(model, clause, args)]
              else
                args.map { |arg| for_arg(model, clause, arg) }
              end
            end

            def for_arg(model, clause, arg, *args)
              default = [Link.new(clause, arg, *args)]

              Link.for_clause(clause, arg, model, *args) || default
            end

            def converted_keys(model, arg)
              arg.is_a?(Hash) ? Hash[arg.map { |key, value| [converted_key(model, key), value] }] : arg
            end

            def converted_key(model, key)
              if key.to_sym == :id
                model ? model.id_property_name : :uuid
              else
                key
              end
            end

            def converted_value(model, key, value)
              model.declared_properties.value_for_where(key, value)
            end
          end
        end
      end
    end
  end
end
