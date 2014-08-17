module Neo4j::ActiveRel
  module Initialize
    extend ActiveSupport::Concern
    include Neo4j::TypeConverters

    attr_reader :_persisted_obj

    # called when loading the rel from the database
    # @param [Hash] properties properties of this relationship
    # @param [Neo4j::Relationship] start_node the starting node in the relationship.
    # @param [Neo4j::Relationship] end_node the ending node in the relationship
    # @param [String] type the relationship type
    def init_on_load(persisted_rel, start_node_id, end_node_id, type)
      @_persisted_obj = persisted_rel
      @rel_type = type
      changed_attributes && changed_attributes.clear
      @attributes = attributes.merge(persisted_rel.props.stringify_keys)
      load_nodes(start_node_id, end_node_id)
      self.default_properties = persisted_rel.props
      @attributes = convert_properties_to :ruby, @attributes
    end

    # Implements the Neo4j::Node#wrapper and Neo4j::Relationship#wrapper method
    # so that we don't have to care if the node is wrapped or not.
    # @return self
    def wrapper
      self
    end
  end
end