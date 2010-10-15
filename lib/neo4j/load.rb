module Neo4j

  # Module used to load both Nodes and Relationship from the database
  module Load
    def wrapper(node) # :nodoc:
      return node unless node.property?(:_classname)
      to_class(node[:_classname]).load_wrapper(node)
    end

    def to_class(class_name) # :nodoc:
      class_name.split("::").inject(Kernel) {|container, name| container.const_get(name.to_s) }
    end

    # Checks if the given node or node id exists in the database.
    def exist?(node_or_node_id, db = Neo4j.started_db)
      id = node_or_node_id.kind_of?(Fixnum) ?  node_or_node_id : node_or_node_id.id
      load(id, db) != nil
    end
  end
end