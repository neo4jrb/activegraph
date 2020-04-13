module ActiveGraph::Node::Initialize
  extend ActiveSupport::Concern
  include ActiveGraph::Shared::Initialize

  attr_reader :called_by

  # called when loading the node from the database
  # @param [ActiveGraph::Node] persisted_node the node this class wraps
  # @param [Hash] properties of the persisted node.
  def init_on_load(persisted_node, properties)
    self.class.extract_association_attributes!(properties)
    @_persisted_obj = persisted_node
    changed_attributes_clear!
    @attributes = convert_and_assign_attributes(properties)
  end

  def init_on_reload(reloaded)
    @attributes = nil
    init_on_load(reloaded, reloaded.properties)
  end
end
