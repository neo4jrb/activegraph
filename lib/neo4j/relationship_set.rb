module Neo4j
  # == Represents a set of relationships.
  # See Neo4j::EventHandler
  class RelationshipSet
    def initialize(size=0)
      @relationship_type_set = java.util.HashSet.new(size)
      @relationship_set = java.util.HashSet.new(size)
      @relationship_map = java.util.HashMap.new(size)
    end

    # Adds a relationship to the set
    def add(rel)
      @relationship_type_set.add(RelationshipSetEntry.new(rel.getEndNode().getId(),rel.rel_type))
      relationships(rel.getEndNode().getId()) << rel
      @relationship_set.add(rel.getId)
    end

    # Returns a collection of relationships where the node with the specified end node id is the end node.
    def relationships(end_node_id)
      @relationship_map.get(end_node_id) || add_list(end_node_id)
    end

    # Returns true if the specified relationship is in the set
    def contains_rel?(rel)
      @relationship_set.contains(rel.getId)
    end

    # Returns true if a relationship with the specified end_node_id and relationship_type is present in the set.
    def contains?(end_node_id,relationship_type)
      @relationship_type_set.contains(RelationshipSetEntry.new(end_node_id,relationship_type))
    end

    protected
    def add_list(node_id)
      @relationship_map.put(node_id,[])
      @relationship_map.get(node_id)
    end
  end

  class RelationshipSetEntry
    attr_accessor :nodeid, :relationship_type
    def initialize(nodeid,relationship_type)
      @nodeid,@relationship_type = nodeid.to_s, relationship_type.to_s
    end

    def ==(o)
      eql?(o)
    end

    def eql?(other)
      @nodeid == other.nodeid && @relationship_type == other.relationship_type
    end

    def hash
      3 * @nodeid.hash + @relationship_type.hash
    end
  end
end