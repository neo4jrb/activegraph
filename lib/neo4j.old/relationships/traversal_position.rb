module Neo4j
  module Relationships

    # Wrapper for org.neo4j.graphdb.TraversalPosition
    # See Javadoc for org.neo4j.graphdb.TraversalPosition
    # It can be used as a parameter in traversals filter functions.
    #
    # :api: public
    class TraversalPosition
      def initialize(traversal_position, raw = false)
        @traversal_position = traversal_position
        @raw = raw
      end

      # Return the current node.
      def current_node
        Neo4j.load_node(@traversal_position.currentNode.getId, @raw)
      end

      # Returns the previous node, may be nil.
      def previous_node
        return nil if @traversal_position.previousNode.nil?
        Neo4j.load_node(@traversal_position.previousNode.getId, @raw)
      end

      # Return the last relationship traversed, may be nil.
      def last_relationship_traversed
        relationship = @traversal_position.lastRelationshipTraversed()
        return nil if relationship.nil?
        return relationship.wrapper unless @raw
        relationship
      end

      # Returns the current traversal depth.
      def depth
        @traversal_position.depth
      end

      # Returns true if the current position is the start node, false otherwise.
      def start_node?
        @traversal_position.isStartNode
      end

      # Returns the number of nodes returned by traverser so far.
      def returned_nodes_count
        @traversal_position.returnedNodesCount
      end
    end
  end
end