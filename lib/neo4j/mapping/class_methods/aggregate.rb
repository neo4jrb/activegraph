module Neo4j::Mapping
  module ClassMethods
    class Aggregates
      class << self
        def add(clazz, field, &block)
          clazz = clazz.to_s
          @aggregates ||= {}
          @aggregates[clazz] ||= {}
          filter = block.nil? ? Proc.new{|*| true} : block
          @aggregates[clazz][field] = filter
        end

        def fields_for(clazz)
          clazz = clazz.to_s
          return [] if @aggregates.nil? || @aggregates[clazz].nil?
          @aggregates[clazz].keys
        end

        def delete(clazz)
          clazz = clazz.to_s
          # delete the aggregate node if found
          if Neo4j.ref_node.rel?(clazz)
            Neo4j.ref_node.outgoing(clazz).each { |n| n.del }
          end
          @aggregates.delete(clazz) if @aggregates
        end

        def on_neo4j_started(*)
          create_aggregates if @aggregates
        end

        def create_aggregates
          @aggregates.each_key do |clazz|
            # check if aggregate nodes exist, if note create them
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
          @aggregates && node.property?(:_classname) && @aggregates.include?(node[:_classname])
        end

        def aggregate_for(clazz)
          Neo4j.ref_node.outgoing(clazz).first
        end


        def on_property_changed(node, key, old_value, new_value)
          return unless trigger?(node)
          clazz = node[:_classname]
          return if @aggregates[clazz].nil?
          agg_node = aggregate_for(node[:_classname])
          @aggregates[clazz].each_pair do |field, filter|
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

      # Creates an aggregate node attached to the Neo4j.ref_node
      # Can be used to aggregate all instances of a specific Ruby class.
      #
      # Example of usage:
      #   class Person
      #     include Neo4j
      #     aggregate :all
      #     aggregate :young { self[:age] < 10 }
      #   end
      #
      #   p1 = Person.new :age => 5
      #   p2 = Person.new :age => 7
      #   p3 = Person.new :age => 12
      #   Neo4j::Transaction.finish
      #   Person.all    # =>  [p1,p2,p3]
      #   Person.young  # =>  [p1,p2]
      #
      def aggregate(name, &block)
        singelton = class << self;
          self;
        end

        singelton.send(:define_method, name) do
          agg_node = Aggregates.aggregate_for(self)
          raise "no aggregate node for #{name}  on #{self}" if agg_node.nil?
          traversal = agg_node.outgoing(name) # TODO possible to cache this object
          Aggregates.fields_for(self).each do |filter_name|
            traversal.filter_method(filter_name) do |path|
              path.end_node.rel?(filter_name, :incoming)
            end
          end
          traversal
        end

        Aggregates.add(self, name, &block)
      end

      # This is typically used for RSpecs to clean up aggregate nodes created by the #aggregate method.
      # It also remove the given class method.
      def delete_aggregates
        singelton = class << self; self;  end
        Aggregates.fields_for(self).each do |name|
          singelton.send(:remove_method, name)
        end
        Aggregates.delete(self)
      end
    end

    Neo4j.unstarted_db.event_handler.add(Aggregates)
  end
end
