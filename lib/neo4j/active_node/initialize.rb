module Neo4j::ActiveNode::Initialize
  extend ActiveSupport::Concern
  include Neo4j::TypeConverters

  attr_reader :_persisted_node

  # called when loading the node from the database
  # @param [Neo4j::Node] persisted_node the node this class wraps
  # @param [Hash] properties of the persisted node.
  def init_on_load(persisted_node, properties)
    @_persisted_node = persisted_node
    @changed_attributes && @changed_attributes.clear
    @attributes = attributes.merge(properties.stringify_keys)
    @attributes = convert_properties_to :ruby, @attributes
  end

  # Implements the Neo4j::Node#wrapper and Neo4j::Relationship#wrapper method
  # so that we don't have to care if the node is wrapped or not.
  # @return self
  def wrapper
    self
  end

end


