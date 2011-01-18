module Neo4j::Mapping


  # Holds all defined rules and trigger them when an event is received.
  #
  # See Neo4j::Mapping::ClassMethods::Rule
  #
  class Rule #:nodoc:

    attr_reader :rule_name, :filter, :triggers, :functions

    def initialize(rule_name, props, &block)
      @rule_name = rule_name
      @triggers  = props[:triggers]
      @functions = props[:functions]
      @triggers  = [@triggers] if @triggers && !@triggers.respond_to?(:each)
      @functions = [@functions] if @functions && !@functions.respond_to?(:each)
      @filter    = block.nil? ? Proc.new { |*| true } : block
    end

    def to_s
      "Rule #{rule_name} props=#{props.inspect}"
    end

    def find_function(function_name, function_id)
      function_id = function_id.to_s
      @functions && @functions.find{|f| f.function_id == function_id && f.class.function_name == function_name}
    end

    # Reconstruct the properties given when created this rule
    # Needed when inheriting a rule and we want to duplicate a rule
    def props
      props = {}
      props[:triggers] = @triggers if @triggers
      props[:functions] = @functions if @functions
      props
    end

    def functions_for(property)
      @functions && @functions.find_all { |f| f.calculate?(property) }
    end

    def execute_filter(node)
      if @filter.arity != 1
        node.wrapper.instance_eval(&@filter)
      else
        @filter.call(node)
      end
    end

    # ------------------------------------------------------------------------------------------------------------------
    # Class Methods
    # ------------------------------------------------------------------------------------------------------------------

    class << self
      def add(clazz, rule_name, props, &block)
        rule_node          = rule_node_for(clazz.to_s)
        rule_node.remove_rule(rule_name) # remove any previously inherited rules
        rule_node.add_rule(rule_name, props, &block)
      end

      def rule_names_for(clazz)
        rule_node = rule_node_for(clazz)
        rule_node.rules.map { |rule| rule.rule_name }
      end

      def rule_node_for(clazz)
        return nil if clazz.nil?
        @rule_nodes             ||= {}
        @rule_nodes[clazz.to_s] ||= RuleNode.new(clazz)
      end

      def inherit(parent_class, subclass)
        # copy all the rules
        if rule_node = rule_node_for(parent_class)
          rule_node.inherit(subclass)
        end
      end

      def delete(clazz)
        if rule_node = rule_node_for(clazz)
          rule_node.delete_node
        end
      end

      def trigger?(node)
        classname = node[:_classname]
        @rule_nodes && classname && rule_node_for(classname)
      end

      def trigger_rules(node, *changes)
        classname = node[:_classname]
        rule_node = rule_node_for(classname)
        rule_node.execute_rules(node, *changes)

        # recursively add relationships for all the parent classes with rules that also pass for this node
        if (clazz = eval("#{classname}.superclass")) && clazz.include?(Neo4j::NodeMixin)
          rule_node = rule_node_for(clazz)
          rule_node && rule_node.execute_rules(node, *changes)
        end
      end


      # ----------------------------------------------------------------------------------------------------------------
      # Event handling methods
      # ----------------------------------------------------------------------------------------------------------------

      def on_relationship_created(rel, *)
        trigger_start_node = trigger?(rel._start_node)
        trigger_end_node   = trigger?(rel._end_node)
        trigger_rules(rel._start_node) if trigger_start_node
        trigger_rules(rel._end_node) if trigger_end_node
      end

      def on_property_changed(node, *changes)
        trigger_rules(node, *changes) if trigger?(node)
      end

      def on_node_deleted(node, old_properties, data)
        # have we deleted a rule node ?
        del_rule_node = @rule_nodes && @rule_nodes.values.find{|rn| rn.rule_node?(node)}
        del_rule_node && del_rule_node.clear_rule_node
        return if del_rule_node

        # do we have prop_aggregations for this
        clazz     = old_properties['_classname']
        rule_node = rule_node_for(clazz)
        return if rule_node.nil?

        id = node.getId
        rule_node.rules.each do |rule|
          next if rule.functions.nil?
          rule_name = rule.rule_name.to_s

          # is the rule node deleted ?
          deleted_rule_node = data.deletedNodes.find{|n| n == rule_node.rule_node}
          next if deleted_rule_node
          
          rule.functions.each do |function|
            next unless data.deletedRelationships.find do |r|
              r.getEndNode().getId() == id && r.rel_type == rule_name
            end
            previous_value = old_properties[function.function_id]
            function.delete(rule_name, rule_node.rule_node, previous_value) if previous_value
          end if rule.functions
        end
      end

      def on_neo4j_started(*)
        @rule_nodes.each_value { |rule_node| rule_node.on_neo4j_started } if @rule_nodes
      end

    end
  end
end
