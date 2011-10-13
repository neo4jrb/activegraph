module Neo4j

  # === Mixin responsible for loading Ruby wrappers for Neo4j Nodes and Relationship.
  #
  module Load
    def wrapper(entity) # :nodoc:
      return entity unless entity.property?(:_classname)
      existing_instance = Neo4j::IdentityMap.get(entity)
      return existing_instance if existing_instance
      new_instance = to_class(entity[:_classname]).load_wrapper(entity)
      Neo4j::IdentityMap.add(entity, new_instance)
      new_instance
    end

    def to_class(class_name) # :nodoc:
      class_name.split("::").inject(Kernel) {|container, name| container.const_get(name.to_s) }
    end

    # Checks if the given entity (node/relationship) or entity id (#neo_id) exists in the database.
    def exist?(entity_or_entity_id, db = Neo4j.started_db)
      id = entity_or_entity_id.kind_of?(Fixnum) ?  entity_or_entity_id : entity_or_entity_id.id
      _load(id, db) != nil
    end
  end
end