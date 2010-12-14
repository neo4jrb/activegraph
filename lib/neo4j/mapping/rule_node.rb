module Neo4j::Mapping


  class RuleNode
    attr_reader :rules

    def initialize(clazz)
      @clazz = clazz
      @rules = []
    end

    def to_s
      "RuleNode #{@clazz}, rules: #{@rules.inspect}"
    end
    
    def node_exist?
      !Neo4j.ref_node.rel?(@clazz)
    end

    def create_node
      Neo4j::Transaction.run do
        node = Neo4j::Node.new
        Neo4j.ref_node.outgoing(@clazz) << node
        node
      end
    end

    def inherit(subclass)
      @rules.each do |rule|
        subclass.rule rule.rule_name, rule.props, &rule.filter
      end
    end

    def delete_node
      if Neo4j.ref_node.rel?(@clazz)
        Neo4j.ref_node.outgoing(@clazz).each { |n| n.del }
      end
      clear_rule_node
    end

    def find_node
      Neo4j.ref_node.rel?(@clazz) && Neo4j.ref_node._rel(:outgoing, @clazz)._end_node
    end

    def on_neo4j_started
      # initialize the rule node when neo4j starts
      rule_node
    end

    def rule_node
      @rule_node ||= find_node || create_node
    end

    def rule_node?(node)
      @rule_node == node
    end

    def clear_rule_node
      @rule_node = nil
    end

    def rule_names
      @rules.map { |r| r.rule_name }
    end

    def find_rule(rule_name)
      @rules.find { |rule| rule.rule_name == rule_name }
    end

    def add_rule(rule_name, props, &block)
      @rules << (rule = Rule.new(rule_name, props, &block))
      rule
    end

    def remove_rule(rule_name)
      r = find_rule(rule_name)
      r && @rules.delete(r)
    end

    # Return a traversal object with methods for each rule and function.
    # E.g. Person.all.old or Person.all.sum(:age)
    def traversal(rule_name)
      # define method on the traversal
      traversal = rule_node.outgoing(rule_name)
      @rules.each do |rule|
        traversal.filter_method(rule.rule_name) do |path|
          path.end_node.rel?(rule.rule_name, :incoming)
        end
        rule.functions && rule.functions.each do |func|
          traversal.functions_method(func, self, rule_name)
        end
      end
      traversal
    end

    def find_function(rule_name, function_name, function_id)
      rule = find_rule(rule_name)
      rule.find_function(function_name, function_id)
    end

    def execute_rules(node, *changes)
      @rules.each do |rule|
        execute_rule(rule, node, *changes)
        execute_other_rules(rule, node)
      end
    end

    def execute_other_rules(rule, node)
      rule.triggers && rule.triggers.each do |rel_type|
        node.incoming(rel_type).each { |n| n.trigger_rules }
      end
    end

    def execute_rule(rule, node, *changes)
      if rule.execute_filter(node)
        if connected?(rule.rule_name, node)
          # it was already connected - the node is in the same rule group but a property has changed
          execute_update_functions(rule, *changes)
        else
          # the node has changed or is in a new rule group
          connect(rule.rule_name, node)
          execute_add_functions(rule, *changes)
        end
      else
        if break_connection(rule.rule_name, node)
          # the node has been removed from a rule group
          execute_delete_functions(rule, *changes)
        end
      end
    end

    def execute_update_functions(rule, *changes)
      if functions = find_functions_for_changes(rule, *changes)
        functions && functions.each { |f| f.update(rule.rule_name, rule_node, changes[1], changes[2]) }
      end
    end

    def execute_add_functions(rule, *changes)
      if functions = find_functions_for_changes(rule, *changes)
        functions && functions.each { |f| f.add(rule.rule_name, rule_node, changes[2]) }
      end
    end

    def execute_delete_functions(rule, *changes)
      if functions = find_functions_for_changes(rule, *changes)
        functions.each { |f| f.delete(rule.rule_name, rule_node, changes[1]) }
      end
    end

    def find_functions_for_changes(rule, *changes)
      # changes = [property, old_value, new_value]
      !changes.empty? && rule.functions_for(changes[0])
    end

    # work out if two nodes are connected by a particular relationship
    # uses the end_node to start with because it's more likely to have less relationships to go through
    # (just the number of superclasses it has really)
    def connected?(rule_name, end_node)
      end_node.incoming(rule_name).find { |n| n == rule_node }
    end

    def connect(rule_name, end_node)
      rule_node.outgoing(rule_name) << end_node
    end

    # sever a direct one-to-one relationship if it exists
    def break_connection(rule_name, end_node)
      rel = end_node._rels(:incoming, rule_name).find { |r| r._start_node == rule_node }
      rel && rel.del
      !rel.nil?
    end

  end


end

