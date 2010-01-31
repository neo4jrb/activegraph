module Neo4j

  org.neo4j.kernel.impl.core.RelationshipProxy.class_eval do
    include Neo4j::JavaPropertyMixin
    include Neo4j::JavaRelationshipMixin

    # TODO DUPLICATED METHODS - end_node, start_node, other_node
    # Why do I need to declare it here as well as in Neo4j::JavaRelationshipMixin ? JRuby Bug ?
    # Maybe because we are overriding the getStartNode and getEndNode methods defined on the java object
    # with start_node and end_node ?

    # Returns the end node of this relationship
    def end_node
      id = getEndNode.getId
      Neo4j.load_node(id)
    end

    # Returns the start node of this relationship
    def start_node
      id = getStartNode.getId
      Neo4j.load_node(id)
    end

    # A convenience operation that, given a node that is attached to this relationship, returns the other node.
    # For example if node is a start node, the end node will be returned, and vice versa.
    # This is a very convenient operation when you're manually traversing the node space by invoking one of the #rels operations on node.
    #
    # This operation will throw a runtime exception if node is neither this relationship's start node nor its end node.
    #
    # ==== Example
    # For example, to get the node "at the other end" of a relationship, use the following:
    #   Node endNode = node.rel(:some_rel_type).other_node(node)
    #
    def other_node(node)
      neo_node = node
      neo_node = node._java_node if node.respond_to?(:_java_node)
      id = getOtherNode(neo_node).getId
      Neo4j.load_node(id)
    end

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
  # See also the Neo4j::RelationshipMixin if you want to wrap a relationship with your own Ruby class.
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


