module Neo4j::Mapping
  module ClassMethods
    class Rules
      class << self
        def add(clazz, field, &block)
          clazz = clazz.to_s
          @rules ||= {}
          @rules[clazz] ||= {}
          filter = block.nil? ? Proc.new{|*| true} : block
          @rules[clazz][field] = filter
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
          create_rules if @rules
        end

        def create_rules
          @rules.each_key do |clazz|
            # check if rule nodes exist, if note create them
            if !Neo4j.ref_node.rel?(clazz)
              Neo4j::Transaction.run do
                node = Neo4j::Node.new
                Neo4j.ref_node.outgoing(clazz) << node
                node
              end
            end
          end
        end


        def trigger?(node)
          @rules && node.property?(:_classname) && @rules.include?(node[:_classname])
        end

        def rule_for(clazz)
          Neo4j.ref_node.outgoing(clazz).first
        end


        def on_property_changed(node, key, old_value, new_value)
          return unless trigger?(node)
          clazz = node[:_classname]
          return if @rules[clazz].nil?
          agg_node = rule_for(node[:_classname])
          @rules[clazz].each_pair do |field, filter|
            if filter.call(node)
              # is this node already included ?
              if !node.rel?(field)
                agg_node.outgoing(field) << node
              end
            else
              # remove old ?
              node.rels(field).incoming.each { |x| x.del }
            end
          end
        end
      end
    end


    module Aggregate

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
      def rule(name, &block)
        singelton = class << self;
          self;
        end

        # define class methods
        singelton.send(:define_method, name) do
          agg_node = Rules.rule_for(self)
          raise "no rule node for #{name}  on #{self}" if agg_node.nil?
          traversal = agg_node.outgoing(name) # TODO possible to cache this object
          Rules.fields_for(self).each do |filter_name|
            traversal.filter_method(filter_name) do |path|
              path.end_node.rel?(filter_name, :incoming)
            end
          end
          traversal
        end

        # define instance methods
        self.send(:define_method, "#{name}?") do
          instance_eval &block
        end

        Rules.add(self, name, &block)
      end

      # This is typically used for RSpecs to clean up rule nodes created by the #rule method.
      # It also remove the given class method.
      def delete_rules
        singelton = class << self; self;  end
        Rules.fields_for(self).each do |name|
          singelton.send(:remove_method, name)
        end
        Rules.delete(self)
      end
    end

    Neo4j.unstarted_db.event_handler.add(Rules)
  end
end
