module Neo4j
  module Functions
    class Count < Function
      def initialize
        @property == '_classname'
      end

      def update(rule_name, rule_node, old_value, new_value)
        key            = rule_node_property(rule_name)
        rule_node[key] ||= 0
        if new_value
          rule_node[key] += 1
        else
          rule_node[key] -= 1
        end
      end

      def self.function_name
        :sum
      end
    end
  end
end
