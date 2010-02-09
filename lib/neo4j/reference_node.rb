module Neo4j

  # There is only one reference node in a neo space, which can always been found (Neo4j::Neo#:ref_node).
  # This is a "starting point" in the node space.
  # Usually, a client attaches relationships to this node that leads into various parts of the node space.
  # For more information about common node space organizational patterns, see the design guide at http://neo4j.org/doc.
  #
  # You can add your own has_n or has_list, has_one relationship to this node.
  #
  class ReferenceNode
    include Neo4j::NodeMixin
    include Neo4j::MigrationMixin
  end

end