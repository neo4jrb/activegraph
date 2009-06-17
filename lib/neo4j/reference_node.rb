module Neo4j

  #
  # Holds references to all other nodes
  # The classname of the nodes are used as the name of the relationship to those nodes.
  # There is only one reference node in a neo space, which can always been found (Neo4j::Neo#:ref_node)
  #
  class ReferenceNode
    include Neo4j::NodeMixin
  end

end