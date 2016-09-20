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
            if @arg.respond_to?(:call)
              @arg.call(var, rel_var)
            else
              [@arg] + @args
            end
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
                    result << new_for_key_and_value(model, key, value)
                  end
                end
              elsif arg.is_a?(String)
                result << new(:where, arg, args)
              end
              result
            end
            alias_method :for_node_where_clause, :for_where_clause

            def for_where_not_clause(*args)
              for_where_clause(*args).each do |link|
                link.instance_variable_set('@clause', :where_not)
              end
            end

            def new_for_key_and_value(model, key, value)
              key = (key.to_sym == :id ? model.id_property_name : key)

              val = if !model
                      value
                    elsif key == model.id_property_name && value.is_a?(Neo4j::ActiveNode)
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

            def for_rel_order_clause(arg, _)
              [new(:order, ->(_, v) { arg.is_a?(String) ? arg : {v => arg} })]
            end

            def for_order_clause(arg, _)
              [new(:order, ->(v, _) { arg.is_a?(String) ? arg : {v => arg} })]
            end

            def for_args(model, clause, args, association = nil)
              if [:where, :where_not].include?(clause) && args[0].is_a?(String) # Better way?
                [for_arg(model, clause, args[0], *args[1..-1])]
              elsif clause == :rel_where
                args.map { |arg| for_arg(model, clause, arg, association) }
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

            def converted_value(model, key, value)
              model.declared_properties.value_for_where(key, value)
            end
          end
        end
      end
    end
  end
end
