module Neo4j

  class Aggregates
    class << self
      def add(clazz, field, &block)
        clazz = clazz.to_s
        @aggregates ||= {}
        @aggregates[clazz] ||= {}
        @aggregates[clazz][:field] = field
        @aggregates[clazz][:block] = block
      end

      def delete(clazz)
        clazz = clazz.to_s
        # delete the aggregate node if found
        if Neo4j.ref_node.rel?(clazz)
          Neo4j.ref_node.outgoing(clazz).each { |n| puts "delete rel #{n.neo_id}"; n.del }
        end
        @aggregates.delete(clazz) if @aggregates
      end

      def on_neo4j_started(db)
        create_aggregates if @aggregates
      end

      def create_aggregates
        @aggregates.each_pair do |clazz, agg_data|
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

      def on_node_created(node)
        return unless trigger?(node)
        agg_node = aggregate_for(node[:_classname])
        agg_node.outgoing(:_class_aggregate) << node
      end

    end
  end


  module AggregateMixin

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
      singelton = class << self; self; end

      singelton.send(:define_method, name) do
        n = Aggregates.aggregate_for(self)
        n.outgoing(:_class_aggregate) if n
      end

      Aggregates.add(self, name, &block)
    end

    # This is typically used for RSpecs to clean up aggregate nodes created by the #aggregate method.
    # It also remove the given class method.
    def delete_aggregate(name)
#      singelton = class << self; self; end
#      singelton.send(:remove_method, name)
      Aggregates.delete(self)
    end
  end

  Neo4j.unstarted_db.event_handler.add(Aggregates)
end