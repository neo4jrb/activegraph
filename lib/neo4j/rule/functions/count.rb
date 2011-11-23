module Neo4j
  module Rule
    module Functions

      # A function for counting number of nodes of a given class.
      class Count < Function
        def initialize
          @property = '_classname'
        end

        def calculate?(changed_property)
          true
        end

        def delete(rule_name, rule_node, old_value)
          key = rule_node_property(rule_name)
          rule_node[key] ||= 0
          rule_node[key] -= 1
        end

        def add(rule_name, rule_node, new_value)
          key = rule_node_property(rule_name)
          rule_node[key] ||= 0
          rule_node[key] += 1
        end

        def update(*)
          # we are only counting, not interested in property changes
        end

        def classes_changed(rule_name, rule_node, class_change)
          key = rule_node_property(rule_name)
          rule_node[key] ||= 0
          rule_node[key] += class_change.net_change
        end

        def self.function_name
          :count
        end
      end
    end
  end
end
