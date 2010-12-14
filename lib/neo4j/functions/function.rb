module Neo4j
  module Functions

    # The base class of rule functions.
    #
    # You are expected to at least implement two methods:
    # * update :: update the rule node value of this function
    # * function_name :: the name of this function, the name of the generated method - A class method !
    #
    class Function

      # Initialize the the function with a property which is usually the same as the function identity.
      # See the #calculate? method how this property is used.
      #
      def initialize(property)
        @property = property.to_s
      end

      def to_s
        "Function #{self.class.function_name} function_id: #{function_id}"
      end

      # Decides if the function should be called are not
      #
      def calculate?(changed_property)
        @property == changed_property
      end


      # The identity of the function.
      # Used to identify function.
      #
      # ==== Example
      #   Person.sum(:young, :age)
      #
      # In the example above the property :age is the used to identify which function will be called
      # since there could be several sum method. In the example we want use the sum method that uses the :age property.
      #
      def function_id
        @property
      end

      # The value of the rule
      def value(rule_node, rule_name)
        key = rule_node_property(rule_name)
        rule_node[key] || 0
      end

      # Called when a node is removed from a rule group
      # Default is calling update method which is expected to be implemented in a subclass
      def delete(rule_name, rule_node, old_value)
        update(rule_name, rule_node, old_value, nil)
      end

      # Called when a node is added to a rule group
      # Default is calling update method which is expected to be implemented in a subclass
      def add(rule_name, rule_node, new_value)
        update(rule_name, rule_node, nil, new_value)
      end

      # the name of the property that holds the value of the function
      def rule_node_property(rule_name)
        self.class.rule_node_property(self.class.function_name, rule_name, @property)
      end

      def self.rule_node_property(function_name, rule_name, prop)
        "_#{function_name}_#{rule_name}_#{prop}"
      end

    end
  end
end
