module Neo4j

  class Aggregates
    class << self
      def add(clazz, field, &block)
        @aggregates ||= {}
        @aggregates[clazz.to_s] = {:field => field, :block => block}
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

    def aggregate(name, &block)
      singelton = class << self
        self;
      end

      singelton.send(:define_method, name) do
        puts "hoj #{self}"
        n = Aggregates.aggregate_for(self)
        n.outgoing(:_class_aggregate) if n
      end

      Aggregates.add(self, name, &block)
    end
  end

  Neo4j.unstarted_db.event_handler.add(Aggregates)
end