module Neo4j::Mapping
  module ClassMethods


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
    module Rule

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
          rule_node = Neo4j::Mapping::Rule.rule_node_for(self)
          rule_node.traversal(rule_name)
        end unless respond_to?(rule_name)

        # define instance methods
        self.send(:define_method, "#{rule_name}?") do
          instance_eval &block
        end

        rule = Neo4j::Mapping::Rule.add(self, rule_name, props, &block)

        rule.functions && rule.functions.each do |func|
          singleton.send(:define_method, func.class.function_name) do |r_name, *args|
            rule_node = Neo4j::Mapping::Rule.rule_node_for(self)
            function_id = args.empty? ? "_classname" : args[0]
            function = rule_node.find_function(r_name, func.class.function_name, function_id)
            function.value(rule_node.rule_node, r_name)
          end
        end
      end

      def inherit_rules_from(clazz)
        Neo4j::Mapping::Rule.inherit(clazz, self)
      end

      # This is typically used for RSpecs to clean up rule nodes created by the #rule method.
      # It also remove the given class method.
      def delete_rules
        singelton = class << self;
          self;
        end
        rule_node = Neo4j::Mapping::Rule.rule_node_for(self)

        rule_node.rule_names.each {|rule_name| singelton.send(:remove_method, rule_name)}
        rule_node.rules.clear
      end

      # Force to trigger the rules.
      # You don't normally need that since it will be done automatically.
      def trigger_rules(node)
        Neo4j::Mapping::Rule.trigger_rules(node)
      end

    end

    Neo4j.unstarted_db.event_handler.add(Neo4j::Mapping::Rule) unless Neo4j.read_only?
  end
end
