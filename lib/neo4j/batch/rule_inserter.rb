module Neo4j
  module Batch
    class RuleInserter #:nodoc:
      def initialize(inserter)
        @inserter = inserter
      end

      def node_added(node, props)
        classname = props && props['_classname']
        classname && create_rules(node, props, classname)
      end


      def create_rules(node, props, classname)
        rule_node = RuleNode.rule_node_for(classname, @inserter)
        rule_node && rule_node.execute_rules(@inserter, node, props)

        if (clazz = eval("#{classname}.superclass")) && clazz.include?(Neo4j::NodeMixin)
          create_rules(node, props, clazz.to_s)
        end
      end
    end
  end
end