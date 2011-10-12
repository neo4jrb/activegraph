class RelationshipSet
  def initialize()
    @set = java.util.HashSet.new
    @relationship_map = java.util.HashMap.new
  end

  def add(rel)
    @set.add(SetEntry.new(rel.getEndNode().getId(),rel.rel_type))
    relationships(rel.getEndNode().getId()) << rel
  end

  def relationships(node_id)
    @relationship_map.get(node_id) || add_list(node_id)
  end

  def add_list(node_id)
    @relationship_map.put(node_id,[])
    @relationship_map.get(node_id)
  end

  def contains?(node_id,relationship_type)
    @set.contains(SetEntry.new(node_id,relationship_type))
  end
end

class SetEntry
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