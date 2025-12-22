module ActiveGraph::Relationship
  module Initialize
    extend ActiveSupport::Concern
    include ActiveGraph::Shared::Initialize

    # called when loading the rel from the database
    # @param [ActiveGraph::Embedded::EmbeddedRelationship, Neo4j::Server::CypherRelationship] persisted_rel properties of this relationship
    # @param [ActiveGraph::Relationship] from_node_id The neo_id of the starting node of this rel
    # @param [ActiveGraph::Relationship] to_node_id The neo_id of the ending node of this rel
    # @param [String] type the relationship type
    def init_on_load(persisted_rel, from_node_id, to_node_id, type)
      @type = type
      @_persisted_obj = persisted_rel
      changed_attributes_clear!
      @attributes = convert_and_assign_attributes(persisted_rel.properties)
      load_nodes(from_node_id, to_node_id)
    end

    def init_on_reload(unwrapped_reloaded)
      @attributes = nil
      init_on_load(unwrapped_reloaded,
                   unwrapped_reloaded.start_node_element_id,
                   unwrapped_reloaded.end_node_element_id,
                   unwrapped_reloaded.type)
      self
    end
  end
end
