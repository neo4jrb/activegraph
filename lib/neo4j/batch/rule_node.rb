module Neo4j
  module Batch
    class RuleNode #:nodoc:
      attr_reader :node
      delegate :rules, :to => :@wrapped_rule_node

      def initialize(wrapped_rule_node, node)
        @wrapped_rule_node = wrapped_rule_node
        @node              = node
      end

      def execute_rules(inserter, node, props)
        rules.each do |rule|
          if execute_filter(rule, props)
            inserter.create_rel(rule.rule_name, @node, node)
            execute_add_functions(inserter, rule, props)
          end
        end
      end

      def execute_add_functions(inserter, rule, props)
        rule_props = nil
        executed_functions = []
        props.keys.each do |key|
          functions = rule.functions_for(key)
          next unless functions
          functions -= executed_functions
          rule_props ||= clone_node_props(inserter) #inserter.node_props(@node)
          functions.each { |f| executed_functions << f; f.add(rule.rule_name, rule_props, props[key]) }
        end
        rule_props && inserter.set_node_props(@node, rule_props)
      end

      def clone_node_props(inserter)
        hash = {}
        props = inserter.node_props(@node)  # need to clone this since we can't modify it
        props.each_pair{|k,v| hash[k]=v}
        hash
      end
      
      def execute_filter(rule, props)
        if rule.filter.nil?
          true
        elsif rule.filter.arity != 1
          classname = props['_classname'] || 'Neo4j::Node'
          clazz     = Neo4j::Node.to_class(classname)
          wrapper   = clazz.load_wrapper(ActiveSupport::HashWithIndifferentAccess.new(props))
          wrapper.instance_eval(&rule.filter)
        else
          rule.filter.call(ActiveSupport::HashWithIndifferentAccess.new(props))
        end
      end

      class << self
        def rule_node_for(classname, inserter)
          return nil unless Neo4j::Rule::Rule.has_rules?(classname)
          wrapped_rule_node      = Neo4j::Rule::Rule.rule_node_for(classname)
          @rule_nodes            ||= {}
          @rule_nodes[classname] ||= RuleNode.new(wrapped_rule_node, create_node(classname, inserter))
        end

        def create_node(classname, inserter)
          rule_node = inserter.create_node
          inserter.create_rel(classname, inserter.ref_node, rule_node)
          rule_node
        end
      end


    end
  end
end
