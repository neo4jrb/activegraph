module Neo4j

  org.neo4j.kernel.impl.core.RelationshipProxy.class_eval do
    include Neo4j::JavaPropertyMixin
    include Neo4j::JavaRelationshipMixin

    def end_node # :nodoc:
      id = getEndNode.getId
      Neo4j.load_node(id)
    end

    def start_node # :nodoc:
      id = getStartNode.getId
      Neo4j.load_node(id)
    end

    def other_node(node) # :nodoc:
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
  # Relationship are created by invoking the << operator on the rels method on the node as follow:
  #  node.rels.outgoing(:friends) << other_node << yet_another_node
  #
  # or using the Neo4j::Relationship#new method (which does the same thing):
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
  # i.e. start_node, end_node and other_node are guaranteed to always return valid, non-null nodes.
  #
  # See also the Neo4j::RelationshipMixin if you want to wrap a relationship with your own Ruby class.
  #
  # === Included Mixins
  # * Neo4j::JavaPropertyMixin
  # * Neo4j::JavaRelationshipMixin
  #
  # (Those mixin are actually not included in the Neo4j::Relationship but instead directly included in the java class org.neo4j.kernel.impl.core.RelationshipProxy)
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
      # props :: optional properties for the created relationship
      #
      # === Returns
      # org.neo4j.graphdb.Relationship java object
      #
      # === Examples
      #
      #  Neo4j::Relationship.new :friend, node1, node2, :since => '2001-01-02', :status => 'okey'
      #
      def new(type, from_node, to_node, props={})
        Neo4j.create_rel(type, from_node, to_node, props)
      end
    end

  end

end


