module Neo4j

  org.neo4j.impl.core.NodeProxy.class_eval do
    include Neo4j::JavaPropertyMixin
    include Neo4j::JavaNodeMixin
    include Neo4j::JavaListMixin
  end

  class Node
    class << self
      # Returns a org.neo4j.api.core.Node java object (!)
      def new()
        node = Neo4j.create_node
        yield node if block_given?
        Neo4j.event_handler.node_created(node)
        node
      end
    end
  end

end
