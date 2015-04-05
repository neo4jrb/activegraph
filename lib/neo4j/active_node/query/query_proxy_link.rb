module Neo4j
  module ActiveNode
    module Query
      class QueryProxy
        class Link
          attr_reader :clause

          def initialize(clause, arg, args = [])
            @clause = clause
            @arg = arg
            @args = args
          end

          def args(var, rel_var)
            @arg.respond_to?(:call) ? @arg.call(var, rel_var) : [@arg, @args].flatten
          end

          class << self
            def for_clause(clause, arg, model, *args)
              method_to_call = "for_#{clause}_clause"

              send(method_to_call, arg, model, *args)
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
                    result << new(:where, ->(v, _) { {v => {key => value}} })
                  end
                end
              elsif arg.is_a?(String)
                result << new(:where, arg, args)
              end
              result
            end
            alias_method :for_node_where_clause, :for_where_clause

            def for_association(name, value, n_string, model)
              neo_id = value.try(:neo_id) || value
              fail ArgumentError, "Invalid value for '#{name}' condition" if not neo_id.is_a?(Integer)

              dir = model.associations[name].direction

              arrow = dir == :out ? '-->' : '<--'
              [
                new(:match, ->(v, _) { "#{v}#{arrow}(#{n_string})" }),
                new(:where, ->(_, _) { {"ID(#{n_string})" => neo_id.to_i} })
              ]
            end

            # We don't accept strings here. If you want to use a string, just use where.
            def for_rel_where_clause(arg, _)
              arg.each_with_object([]) do |(key, value), result|
                result << new(:where, ->(_, rel_var) { {rel_var => {key => value}} })
              end
            end

            def for_order_clause(arg, _)
              [new(:order, ->(v, _) { arg.is_a?(String) ? arg : {v => arg} })]
            end

            def for_args(model, clause, args)
              if clause == :where && args[0].is_a?(String) # Better way?
                [for_arg(model, :where, args[0], *args[1..-1])]
              else
                args.map { |arg| for_arg(model, clause, arg) }
              end
            end

            def for_arg(model, clause, arg, *args)
              default = [Link.new(clause, arg, *args)]

              Link.for_clause(clause, arg, model, *args) || default
            rescue NoMethodError
              default
            end
          end
        end
      end
    end
  end
end
