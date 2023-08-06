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
              links << new(:call_subquery_start, nil, *args)
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

            def independent_union_subquery_proc(proxy, loop_index)
              proxy_params = proxy.query.parameters
              proxy_cypher = proxy.to_cypher
              subquery_identity = proxy.identity
              uniq_param_generator = uniq_param_generator_lambda

              lambda do |identity, _|
                proxy_params = uniq_param_generator.call(proxy_params, proxy_cypher, identity, loop_index) if proxy_params.present?
                [subquery_identity, proxy_cypher, proxy_params, identity.delete_prefix(OUTER_SUBQUERY_PREFIX)]
              end
            end

            def continuation_union_subquery_proc(outer_proxy, model, subquery_part, loop_index) # rubocop:disable Metrics/AbcSize
              lambda do |identity, _|
                proxy = outer_proxy.as(identity)
                proxy_with_clause = proxy.query.with(proxy.identity).with(proxy.identity).proxy_as(model, proxy.identity)
                complete_query = proxy_with_clause.instance_exec(&subquery_part) || proxy_with_clause
                subquery_cypher = complete_query.to_cypher
                subquery_cypher = subquery_cypher.delete_prefix(proxy.to_cypher) if proxy.send(:chain).present? || proxy.starting_query
                subquery_parameters = (complete_query.query.parameters.to_a - proxy.query.parameters.to_a).to_h

                subquery_parameters = uniq_param_generator_lambda.call(subquery_parameters, subquery_cypher, identity, loop_index) if subquery_parameters.present?
                [complete_query.identity, subquery_cypher, subquery_parameters] + [identity.delete_prefix(OUTER_SUBQUERY_PREFIX)]
              end
            end

            def uniq_param_generator_lambda
              lambda do |proxy_params, proxy_cypher, identity, counter|
                prefix = "#{identity}_UNION#{counter}_"
                proxy_params.each_with_object({}) do |(param_name, param_val), new_params|
                  new_params_key = "#{prefix}#{param_name}".to_sym
                  new_params[new_params_key] = param_val
                  proxy_cypher.gsub!(/\$#{param_name}(?=([^`'"]|'(\\.|[^'])*'|"(\\.|[^"])*"|`(\\.|[^`])*`)*[^'"`]*\z)/, "$#{new_params_key}")
                  new_params
                end
              end
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
              elsif arg.is_a?(String)
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
                    elsif key == model.id_property_name && value.is_a?(ActiveGraph::Node)
                      value.id
                    else
                      converted_value(model, key, value)
                    end

              new(:where, ->(v, _) { {v => {key => val}} })
            end

            def for_association(name, value, n_string, model)
              neo_id = value.try(:neo_id) || value
              fail ArgumentError, "Invalid value for '#{name}' condition" if not neo_id.is_a?(Integer)

              [
                new(:match, ->(v, _) { "(#{v})#{model.associations[name].arrow_cypher}(#{n_string})" }),
                new(:where, ->(_, _) { {"ID(#{n_string})" => neo_id.to_i} })
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
