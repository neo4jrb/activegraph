module Neo4j::ActiveRel
  module Initialize
    extend ActiveSupport::Concern
    include Neo4j::Shared::Initialize

    # called when loading the rel from the database
    # @param [Neo4j::Embedded::EmbeddedRelationship, Neo4j::Server::CypherRelationship] persisted_rel properties of this relationship
    # @param [Neo4j::Relationship] from_node_id The neo_id of the starting node of this rel
    # @param [Neo4j::Relationship] to_node_id The neo_id of the ending node of this rel
    # @param [String] type the relationship type
    def init_on_load(persisted_rel, from_node_id, to_node_id, type)
      @rel_type = type
      @_persisted_obj = persisted_rel
      changed_attributes && changed_attributes.clear
      @attributes = convert_and_assign_attributes(persisted_rel.props)
      load_nodes(from_node_id, to_node_id)
    end

    def init_on_reload(unwrapped_reloaded)
      @attributes = nil
      init_on_load(unwrapped_reloaded,
                   unwrapped_reloaded._start_node_id,
                   unwrapped_reloaded._end_node_id,
                   unwrapped_reloaded.rel_type)
      self
    end
  end
end
