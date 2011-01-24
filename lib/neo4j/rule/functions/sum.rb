module Neo4j
  module Rule
    module Functions

      class Sum < Function
        # Updates the function's value.
        # Called after the transactions commits and a property has been changed on a node.
        #
        # ==== Arguments
        # * rule_name :: the name of the rule group
        # * rule_node :: the node which contains the value of this function
        # * old_value new value :: the changed value of the property (when the transaction commits)
        def update(rule_name, rule_node, old_value, new_value)
          key = rule_node_property(rule_name)
          rule_node[key] ||= 0
          old_value ||= 0
          new_value ||= 0
          rule_node[key] += new_value - old_value
        end

        def self.function_name
          :sum
        end
      end


    end
  end
end
