module Neo4j::Mapping
  module ClassMethods
    # Holds all defined rules and trigger them when an event is received.
    #
    # See Rule
    # 
    class Rules
      class << self
        def add(clazz, field, props, &block)
          clazz                   = clazz.to_s
          @rules                  ||= {}
          # was there no rules for this class AND is neo4j running ?
          if !@rules.include?(clazz) && Neo4j.running?
            # maybe Neo4j was started first and the rules was added later. Create rule nodes now
            create_rule_node_for(clazz)
          end
          @rules[clazz]           ||= {}
          filter                  = block.nil? ? Proc.new { |*| true } : block
          @rules[clazz][field]    = filter
          @triggers               ||= {}
          @triggers[clazz]        ||= {}
          trigger                 = props[:trigger].nil? ? [] : props[:trigger]
          @triggers[clazz][field] = trigger.respond_to?(:each) ? trigger : [trigger]
          @prop_aggregations ||= {}
        end

        def add_prop_aggregation(clazz, prop_aggregation, rule_name, prop)
          # TODO, I guess this datastructure is a bit deep :-)
          rule_name = rule_name.to_sym
          prop = prop.to_s
          @prop_aggregations ||= {}
          @prop_aggregations[clazz.to_s] ||= {}
          @prop_aggregations[clazz.to_s][rule_name] ||= {}
          @prop_aggregations[clazz.to_s][rule_name][prop] ||= []
          raise "Already included aggregate #{clazz}" if @prop_aggregations[clazz.to_s][rule_name][prop].include?(prop_aggregation)
          @prop_aggregations[clazz.to_s][rule_name][prop] << prop_aggregation
        end

        def inherit(parent_class, subclass)
          # copy all the rules
          @rules[parent_class.to_s].each_pair do |field, filter|
            subclass.rule field, &filter
          end if @rules[parent_class.to_s]
        end

        def trigger_other_rules(node)
          clazz = node[:_classname]
          @rules[clazz].keys.each do |field|
            rel_types = @triggers[clazz][field]
            rel_types.each do |rel_type|
              node.incoming(rel_type).each { |n| n.trigger_rules }
            end
          end
        end

        def fields_for(clazz)
          clazz = clazz.to_s
          return [] if @rules.nil? || @rules[clazz].nil?
          @rules[clazz].keys
        end

        def delete(clazz)
          clazz = clazz.to_s
          # delete the rule node if found
          if Neo4j.ref_node.rel?(clazz)
            Neo4j.ref_node.outgoing(clazz).each { |n| n.del }
          end
          @rules.delete(clazz) if @rules
        end

        def on_neo4j_started(*)
          @rules.each_key { |clazz| create_rule_node_for(clazz) } if @rules
        end

        def create_rule_node_for(clazz)
          if !Neo4j.ref_node.rel?(clazz)
            Neo4j::Transaction.run do
              node = Neo4j::Node.new
              Neo4j.ref_node.outgoing(clazz) << node
              node
            end
          end
        end

        def trigger?(node)
          @rules && node.property?(:_classname) && @rules.include?(node[:_classname])
        end

        def rule_for(clazz)
          if Neo4j.ref_node.rel?(clazz)
            Neo4j.ref_node._rel(:outgoing, clazz)._end_node
          else
            # this should be called if the rule node gets deleted
            create_rule_node_for(clazz)
          end
        end


        def on_relationship_created(rel, *)
          trigger_start_node = trigger?(rel._start_node)
          trigger_end_node   = trigger?(rel._end_node)
          # end or start node must be triggered by this event
          return unless trigger_start_node || trigger_end_node
          on_property_changed(trigger_start_node ? rel._start_node : rel._end_node)
        end


        def on_property_changed(node, *changes)
          trigger_rules(node, *changes) if trigger?(node)
        end

        def on_node_deleted(node, old_properties, data)
          # do we have prop_aggregations for this
          clazz = old_properties['_classname']
          return unless p_class = @prop_aggregations[clazz.to_s]
          rule_node = rule_for(clazz)

          id = node.getId

          p_class.keys.each do |agg_name|
            p_class[agg_name].each_pair do |prop, aggs|
              agg_name = agg_name.to_s
              aggs.each do |agg|
                found = data.deletedRelationships.find {|r| r.getEndNode().getId() == id && r.rel_type == agg_name}
                agg.delete(agg_name, rule_node, prop, nil, old_properties[prop]) if found
              end
            end
          end
        end

        def trigger_rules(node, *changes)
          trigger_rules_for_class(node, node[:_classname], *changes)
          trigger_other_rules(node)
        end

        def prop_aggregates(clazz, rule_name, property)
          return nil unless @prop_aggregations
          return nil unless p_class = @prop_aggregations[clazz.to_s]
#          puts "pp_class #{p_class.inspect}, rule_name #{rule_name.inspect}, property=#{property.inspect}"
          return nil unless p_rule = p_class[rule_name]
          p_rule[property]
        end
        
        def trigger_rules_for_class(node, clazz, *changes)
          return if @rules[clazz].nil?

          agg_node = rule_for(clazz)
          @rules[clazz].each_pair do |field, rule|
            aggs = prop_aggregates(clazz, field, changes[0])
            if run_rule(rule, node)
              # is this node already included ?
              unless connected?(field, agg_node, node)
                agg_node.outgoing(field) << node
              end
              aggs.each {|agg| agg.add(field, agg_node, *changes)} if aggs
            else
              # remove old ?
              if break_connection(field, agg_node, node)
                aggs.each {|agg| agg.delete(field, agg_node, *changes)} if aggs
              end
            end
          end

          # recursively add relationships for all the parent classes with rules that also pass for this node
          if clazz = eval("#{clazz}.superclass")
            trigger_rules_for_class(node, clazz.to_s)
          end
        end

        # work out if two nodes are connected by a particular relationship
        # uses the end_node to start with because it's more likely to have less relationships to go through
        # (just the number of superclasses it has really)
        def connected?(relationship, start_node, end_node)
          end_node.incoming(relationship).each do |n|
            return true if n == start_node
          end
          false
        end

        # sever a direct one-to-one relationship if it exists
        def break_connection(relationship, start_node, end_node)
          end_node.rels(relationship).incoming.each do |r|
            return r.del if r.start_node == start_node
          end
        end

        def run_rule(rule, node)
          if rule.arity != 1
            node.wrapper.instance_eval(&rule)
          else
            rule.call(node)
          end
        end
      end
    end


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
    #     rule(:young, :trigger => :readers) { age < 15 }
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
      #     rule :all
      #     rule :young { self[:age] < 10 }
      #   end
      #
      #   p1 = Person.new :age => 5
      #   p2 = Person.new :age => 7
      #   p3 = Person.new :age => 12
      #   Neo4j::Transaction.finish
      #   Person.all    # =>  [p1,p2,p3]
      #   Person.young  # =>  [p1,p2]
      #   p1.young?    # => true
      #
      def rule(name, props = {}, &block)
        singelton = class << self;
          self;
        end

        # define class methods
        singelton.send(:define_method, name) do
          agg_node  = Rules.rule_for(self)
          raise "no rule node for #{name}  on #{self}" if agg_node.nil?
          traversal = agg_node.outgoing(name) # TODO possible to cache this object
          Rules.fields_for(self).each do |filter_name|
            traversal.filter_method(filter_name) do |path|
              path.end_node.rel?(filter_name, :incoming)
            end
          end
          traversal
        end unless respond_to?(name)

        # define instance methods
        self.send(:define_method, "#{name}?") do
          instance_eval &block
        end

        Rules.add(self, name, props, &block)
      end

      # TODO,
      def rule_obj(rule_clazz, rule_name, prop)
        singelton = class << self
          self
        end
        singelton.send(:define_method, rule_clazz.aggregate_name) do |rule, property|
          agg_node = Rules.rule_for(self)
          puts "Call #{rule} arg #{property}"
          rule_clazz.value(agg_node, rule, property)
        end unless respond_to?(rule_clazz.aggregate_name)

        Rules.add_prop_aggregation(self, rule_clazz, rule_name, prop)
      end

      def inherit_rules_from(clazz)
        Rules.inherit(clazz, self)
      end

      # This is typically used for RSpecs to clean up rule nodes created by the #rule method.
      # It also remove the given class method.
      def delete_rules
        singelton = class << self;
          self;
        end
        Rules.fields_for(self).each do |name|
          singelton.send(:remove_method, name)
        end
        Rules.delete(self)
      end

      # Force to trigger the rules.
      # You don't normally need that since it will be done automatically.
      def trigger_rules(node)
        Rules.trigger_rules(node)
      end

    end

    Neo4j.unstarted_db.event_handler.add(Rules) unless Neo4j.read_only?
  end
end
