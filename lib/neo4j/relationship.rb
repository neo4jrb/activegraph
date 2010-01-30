module Neo4j

  org.neo4j.kernel.impl.core.RelationshipProxy.class_eval do
    include Neo4j::JavaPropertyMixin
    include Neo4j::JavaRelationshipMixin
  end

  #
  # A relationship between two nodes in the graph. A relationship has a start node, an end node and a type.
  # You can attach properties to relationships with the API specified in Neo4j::JavaPropertyMixin.
  #
  # Relationships are created by invoking the << operator on the rels method on the node as follow:
  #  node.rels.outgoing(:friends) << other_node << yet_another_node
  #
  # or using the Neo4j::Relationship.new method (which does the same thing):
  #  rel = Neo4j::Relationship.new(:friends, node, other_node)
  #
  # The fact that the relationship API gives meaning to start and end nodes implicitly means that all relationships have a direction.
  # In the example above, rel would be directed from node to otherNode.
  # A relationship's start node and end node and their relation to outgoing and incoming are defined so that the assertions in the following code are true:
  #
  #   a = Neo4j::Node.new
  #   b = Neo4j::Node.new
  #   rel = Neo4j::Relationship.new(:some_type, a, b)
  #   # Now we have: (a) --- REL_TYPE ---> (b)
  #
  #    rel.start_node # => a
  #    rel.end_node   # => b
  #
  # Furthermore, Neo4j guarantees that a relationship is never "hanging freely,"
  #  i.e. start_node, end_node and other_node are guaranteed to always return valid, non-null nodes.
  #
  class Relationship
    class << self
      # Returns a org.neo4j.graphdb.Relationship java object (!)
      # Will trigger a event that the relationship was created.
      #
      # === Parameters
      # type :: the type of relationship
      # from_node :: the start node of this relationship
      # end_node  :: the end node of this relationship
      #
      # === Returns
      # org.neo4j.graphdb.Relationship java object
      #
      # === Examples
      #
      #  Neo4j::Relationship.new :friend, node1, node2
      #
      def new(type, from_node, to_node)
        from_node.add_rel(type, to_node)
      end
    end

  end

end


