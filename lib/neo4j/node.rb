module Neo4j

  org.neo4j.impl.core.NodeProxy.class_eval do
    include Neo4j::JavaPropertyMixin
    include Neo4j::JavaNodeMixin
    include Neo4j::JavaListMixin
  end

  class Node
    class << self
      # Returns a org.neo4j.api.core.Node java object (!)
      def new(*args)
        node = Neo4j.create_node
        args[0].each_pair{|k,v| node[k] = v} if args.length == 1 && args[0].respond_to?(:each_pair)
        yield node if block_given?
        Neo4j.event_handler.node_created(node)
        node
      end
    end
  end

end
