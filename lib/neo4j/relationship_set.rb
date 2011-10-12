class RelationshipSet
  def initialize()
    @set = java.util.HashSet.new
  end

  def add(node_id,relationship_type)
    @set.add(SetEntry.new(node_id,relationship_type))
  end

  def contains?(node_id,relationship_type)
    @set.contains(SetEntry.new(node_id,relationship_type))
  end
end

class SetEntry
  attr_accessor :nodeid, :relationship_type
  def initialize(nodeid,relationship_type)
    @nodeid,@relationship_type = nodeid, relationship_type
  end

  def ==(o)
    eql?(o)
  end

  def eql?(other)
    @nodeid == other.nodeid && @relationship_type == other.relationship_type
  end

  def hash
    31 * @nodeid.hash + @relationship_type.hash
  end
end