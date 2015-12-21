module Neo4j::ActiveNode::Initialize
  extend ActiveSupport::Concern
  include Neo4j::Shared::Initialize

  attr_reader :called_by

  # called when loading the node from the database
  # @param [Neo4j::Node] persisted_node the node this class wraps
  # @param [Hash] properties of the persisted node.
  def init_on_load(persisted_node, properties)
    self.class.extract_association_attributes!(properties)
    @_persisted_obj = persisted_node
    changed_attributes && changed_attributes.clear
    @attributes = convert_and_assign_attributes(properties)
  end

  def init_on_reload(reloaded)
    @attributes = nil
    init_on_load(reloaded, reloaded.props)
  end
end
