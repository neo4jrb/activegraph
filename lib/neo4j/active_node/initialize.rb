module Neo4j::ActiveNode::Initialize
  extend ActiveSupport::Concern
  attr_reader :called_by

  # called when loading the node from the database
  # @param [Neo4j::Node] persisted_node the node this class wraps
  # @param [Hash] properties of the persisted node.
  def init_on_load(persisted_node, properties)
    self.class.extract_association_attributes!(properties)
    @_persisted_obj = persisted_node
    changed_attributes && changed_attributes.clear
    @attributes ||= self.class.attributes_nil_hash.dup
    stringify_attributes!(@attributes, properties)
    self.default_properties = properties
    @attributes = self.class.declared_property_manager.convert_properties_to(self, :ruby, @attributes)
  end

  # Implements the Neo4j::Node#wrapper and Neo4j::Relationship#wrapper method
  # so that we don't have to care if the node is wrapped or not.
  # @return self
  def wrapper
    self
  end

  private

  def stringify_attributes!(attr, properties)
    properties.each_pair do |k, v|
      key = self.class.declared_property_manager.attributes_string_map[k] || k.to_s
      attr[key] = v
    end
  end
end
