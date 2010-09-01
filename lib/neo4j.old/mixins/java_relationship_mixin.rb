# This is a mixin that is used to extend the java object org.neo4j.graphdb.Relationship
#
module Neo4j::JavaRelationshipMixin

  # Deletes this relationship.
  #
  def del
    Neo4j.event_handler.relationship_deleted(wrapper)
    type = getType().name()

    delete

    if end_node.class.respond_to?(:indexer)
      end_node.class.indexer.on_relationship_deleted(end_node, type)
    elsif end_node.wrapper?
      end_node.wrapper_class.indexer.on_relationship_deleted(end_node.wrapper, type)
    end
  end

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


  # Returns the neo relationship type that this relationship is used in.
  # (see java API org.neo4j.graphdb.Relationship#getType  and org.neo4j.graphdb.RelationshipType)
  #
  # ==== Returns
  # the relationship type (of type Symbol)
  #
  def relationship_type
    get_type.name.to_sym
  end

end
