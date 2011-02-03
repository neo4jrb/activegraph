module Neo4j
  module Rule


    # Allows you to group nodes by providing a rule.
    #
    # === Example, finding all nodes of a certain class
    # Just add a rule without a code block, then all nodes of that class will be grouped under the given key (<tt>all</tt>
    # for the example below).
    #
    #   class Person
    #     include Neo4j::NodeMixin
    #     rule :all
    #   end
    #
    # Then you can get all the nodes of type Person (and siblings) by
    #   Person.all.each {|x| ...}
    #
    # === Example, finding all nodes with a given condition on a property
    #
    #   class Person
    #     include Neo4j::NodeMixin
    #     property :age
    #     rule(:old) { age > 10 }
    #   end
    #
    #  Now we can find all nodes with a property <tt>age</tt> above 10.
    #
    # === Chain Rules
    #
    #   class NewsStory
    #     include Neo4j::NodeMixin
    #     has_n :readers
    #     rule(:featured) { |node| node[:featured] == true }
    #     rule(:young_readers) { !readers.find{|user| !user.young?}}
    #   end
    #
    # You can combine two rules. Let say you want to find all stories which are featured and has young readers:
    #   NewsStory.featured.young_readers.each {...}
    #
    # === Trigger Other Rules
    # You can let one rule trigger another rule.
    # Let say you have readers of some magazine and want to know if the magazine has old or young readers.
    # So when a reader change from young to old you want to trigger all the magazine that he reads (a but stupid example)
    #
    # Example
    #   class Reader
    #     include Neo4j::NodeMixin
    #     property :age
    #     rule(:young, :triggers => :readers) { age < 15 }
    #   end
    #
    #   class NewsStory
    #     include Neo4j::NodeMixin
    #     has_n :readers
    #     rule(:young_readers) { !readers.find{|user| !user.young?}}
    #   end
    #
    # === Performance Considerations
    # If you have many rules and many updates this can be a bit slow.
    # In order to speed it up somewhat you can use the raw java node object instead by providing an argument in your block.
    #
    # Example:
    #
    #   class Person
    #     include Neo4j::NodeMixin
    #     property :age
    #     rule(:old) {|node| node[:age] > 10 }
    #   end
    #
    # === Thread Safe ?
    # Yes, since operations are performed in an transaction. However you may get a deadlock exception:
    # http://docs.neo4j.org/html/snapshot/#_deadlocks
    #
    module ClassMethods

      # Creates an rule node attached to the Neo4j.ref_node
      # Can be used to rule all instances of a specific Ruby class.
      #
      # Example of usage:
      #   class Person
      #     include Neo4j
      #     property :age
      #     rule :all
      #     rule :young { self[:age] < 10 }
      #     rule(:old, :functions => [Sum.new[:age]) { age > 20 }
      #   end
      #
      #   p1 = Person.new :age => 5
      #   p2 = Person.new :age => 7
      #   p3 = Person.new :age => 12
      #   Neo4j::Transaction.finish
      #   Person.all    # =>  [p1,p2,p3]
      #   Person.young  # =>  [p1,p2]
      #   p1.young?    # => true
      #   p1.sum(old, :age) # the some of the old people's age
      #
      def rule(rule_name, props = {}, &block)
        singleton = class << self;
          self;
        end

        # define class methods
        singleton.send(:define_method, rule_name) do
          rule_node = Rule.rule_node_for(self)
          rule_node.traversal(rule_name)
        end unless respond_to?(rule_name)

        # define instance methods
        self.send(:define_method, "#{rule_name}?") do
          instance_eval &block
        end

        rule = Rule.add(self, rule_name, props, &block)

        rule.functions && rule.functions.each do |func|
          singleton.send(:define_method, func.class.function_name) do |r_name, *args|
            rule_node = Rule.rule_node_for(self)
            function_id = args.empty? ? "_classname" : args[0]
            function = rule_node.find_function(r_name, func.class.function_name, function_id)
            function.value(rule_node.rule_node, r_name)
          end unless respond_to?(func.class.function_name)
        end
      end

      def inherit_rules_from(clazz)
        Rule.inherit(clazz, self)
      end

      # This is typically used for RSpecs to clean up rule nodes created by the #rule method.
      # It also remove all the rule class methods.
      def delete_rules
        singelton = class << self;
          self;
        end
        rule_node = Rule.rule_node_for(self)

        rule_node.rule_names.each {|rule_name| singelton.send(:remove_method, rule_name)}
        rule_node.rules.clear
      end

      # Force to trigger the rules.
      # You don't normally need that since it will be done automatically.
      # This can be useful if you need to trigger rules on already existing nodes in the database.
      # Can also be called from an migration.
      #
      def trigger_rules(node, *changes)
        Rule.trigger_rules(node, *changes)
      end

      # Returns a proc that will call add method on the given function
      # Can be used in migration to trigger rules on already existing nodes.
      # Parameter function_id is default to '_classname' which means that
      # the function 'reacts' on changes on the property '_classname'.
      # That property changes only when a node is created or deleted.
      # Function using function_id '_classname' is typically used for counting number of nodes of a class.
      def add_function_for(rule_name, function_name_or_class, function_id = '_classname')
        function_for(:add, rule_name, function_name_or_class, function_id)
      end

      # See #add_function_for
      # Calls the delete method on the function.
      def delete_function_for(rule_name, function_name_or_class, function_id = '_classname')
        function_for(:delete, rule_name, function_name_or_class, function_id)
      end

      # Returns a proc that calls the given method on the given function.
      def function_for(method, rule_name, function_name_or_class, function_id = '_classname')
        function_name = function_name_or_class.is_a?(Symbol)? function_name_or_class : function_name_or_class.function_name
        rule_node = Rule.rule_node_for(self)
        rule = rule_node.find_rule(rule_name)
        rule_node_raw = rule_node.rule_node

        function = rule_node.find_function(rule_name, function_name, function_id)
        lambda do |node|
          new_value = node[function_id]
          function.send(method, rule.rule_name, rule_node_raw, new_value)
        end
      end
    end

  end
end
