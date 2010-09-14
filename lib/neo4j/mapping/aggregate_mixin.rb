module Neo4j

  class Aggregates
    class << self
      def add(clazz, field, &block)
        @aggregates ||= {}
        @aggregates[clazz] = {:field => field, :block => block}
      end


      def on_neo4j_started(db)
        create_aggregates if @aggregates
      end

      def create_aggregates
        @aggregates.each_pair do |clazz, agg_data|
          # check if aggregate nodes exist, if note create them
          if !Neo4j.ref_node.rel?(clazz)
            puts "create agg node #{clazz}"
            Neo4j::Transaction.run do
              node = Neo4j::Node.new
              puts "  create #{node.neo_id} "
              Neo4j.ref_node.outgoing(clazz) << node
              node
            end
          end
        end
      end


      def trigger?(node)
        node.property?(:_classname) && @aggregates.include?(node[:_classname])
      end

      def aggregate_for(clazz)
        puts "aggregates_for #{clazz}"
        Neo4j.ref_node.outgoing(clazz).first
      end

      def on_node_created(node)
        return unless trigger?(node)
        agg_node = aggregate_for(node[:_classname])
        puts " aggregate node #{node.neo_id}"
        agg_node.outgoing(:_class_aggregate) << node
      end

      def on_node_deleted(node)
        puts "deleted node #{node.neo_id}"
      end
    end
  end


  module AggregateMixin

    def aggregate(name, &block)
      puts "aggregate #{self}"
      Aggregates.add(self, name, &block)
      singelton = class << self
        self;
      end

      singelton.send(:define_method, name) do
        puts "hoj #{self}"
        Aggregates.aggregate_for(self).outgoing(:_class_aggregate)
      end

      Aggregates.add(self, name, &block)
    end
  end

  Neo4j.unstarted_db.event_handler.add(Aggregates)
end