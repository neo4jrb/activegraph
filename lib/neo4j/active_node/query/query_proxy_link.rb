module Neo4j
  module ActiveNode
    module Query
      class QueryProxy
        class Link
          attr_reader :clause

          def initialize(clause, arg)
            @clause = clause
            @arg = arg
          end

          def args(var, rel_var)
            @arg.respond_to?(:call) ? @arg.call(var, rel_var) : @arg
          end

          class << self
            def for_clause(clause, arg)
              method_to_call = "for_#{clause}_clause"

              send(method_to_call, arg)
            end

            def for_where_clause(arg)
              node_num = 1
              result = []
              if arg.is_a?(Hash)
                arg.each do |key, value|
                  if @model && @model.association?(key)
                    result += for_association(key, value, "n#{node_num}")

                    node_num += 1
                  else
                    result << new(:where, ->(v, _) { {v => {key => value}} })
                  end
                end
              elsif arg.is_a?(String)
                result << new(:where, arg)
              end
              result
            end
            alias_method :for_node_where_clause, :for_where_clause

            def for_association(name, value, n_string)
              neo_id = value.try(:neo_id) || value
              fail ArgumentError, "Invalid value for '#{name}' condition" if not neo_id.is_a?(Integer)

              dir = @model.associations[name].direction

              arrow = dir == :out ? '-->' : '<--'
              [
                new(:match, ->(v, _) { "#{v}#{arrow}(#{n_string})" }),
                new(:where, ->(_, _) { {"ID(#{n_string})" => neo_id.to_i} })
              ]
            end

            # We don't accept strings here. If you want to use a string, just use where.
            def for_rel_where_clause(arg)
              arg.each_with_object([]) do |(key, value), result|
                result << new(:where, ->(_, rel_var) { {rel_var => {key => value}} })
              end
            end

            def for_order_clause(arg)
              [new(:order, ->(v, _) { arg.is_a?(String) ? arg : {v => arg} })]
            end
          end
        end
      end
    end
  end
end
