module Neo4j
  module Functions
    class Function
      def initialize(property)
        @property = property.to_s
      end

      def calculate?(changed_property)
        @property == changed_property
      end

      def function_id
        @property # TODO change name
      end

      def value(rule_node, rule_name)
        key = rule_node_property(rule_name)
        rule_node[key] || 0
        #puts "ret = #{ret}, key = #{key}, value #{rule_node.props.inspect}, arg=#{rule_name}, #{prop}"
      end

      def delete(rule_name, rule_node, old_value)
        update(rule_name, rule_node, old_value, nil)
      end

      def rule_node_property(rule_name)
        self.class.rule_node_property(self.class.function_name, rule_name, @property)
      end

      def self.rule_node_property(function_name, rule_name, prop)
        "_#{function_name}_#{rule_name}_#{prop}"
      end

      def to_s
        "Function #{self.class.function_name} function_id: #{function_id}"
      end
    end

    class Sum < Function
      # Updates the function's value.
      # Called after the transactions commits and a property has been changed on a node.
      #
      # ==== Arguments
      # * rule_name :: the name of the rule group
      # * rule_node :: the node which contains the value of this function
      # * old_value new value :: the changed value of the property (when the transaction commits)
      def update(rule_name, rule_node, old_value, new_value)
        key            = rule_node_property(rule_name)
        rule_node[key] ||= 0
        old_value      ||= 0
        new_value      ||= 0
        rule_node[key] += new_value - old_value
      end

      def self.function_name
        :sum
      end
    end


  end
end