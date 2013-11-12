module Neo4j::ActiveNode::Initialize

  attr_reader :_persisted_node

  # called when loading the node from the database
  def init_on_load(persisted_node, properties)
    @_persisted_node = persisted_node
    @_properties = properties
  end

  # called when creating a node by #new but not touching the database
  def init_on_new(properties)
    @_properties = properties
  end

  # Implements the Neo4j::Node#wrapper and Neo4j::Relationship#wrapper method
  # so that we don't have to care if the node is wrapped or not.
  # @return self
  def wrapper
    self
  end

end


