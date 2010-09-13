module Neo4j
  class AggregateNode
    include Neo4j::NodeMixin

    def on_node_created(node)
      puts "created node #{node}"
      # TODO
      # which class is it ?
      # should we aggregated it ?
    end
  end


  module AggregateMixin

    def aggregate(name, &block)
      if Neo4j.ref_node.rel?(self)
        puts "already exist"
        @agg_node = Neo4j::Transaction.run {Neo4j.ref_node.outgoing(self).first}
      else
        # TODO, have to wait doing this so it can be configured :storage_path
        @agg_node = Neo4j::Transaction.run do
          puts "create new"
          node = AggregateNode.new
          Neo4j.ref_node.outgoing(self) << node
          puts "node #{node.class}"
          node
        end
      end

      Neo4j.db.event_handler.add(@agg_node)
    end
  end
end