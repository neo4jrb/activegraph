class MockRelationship
end

Neo4j::Relationship.extend_java_class(MockRelationship)

class MockRelationship
  attr_reader :rel_type

  def initialize(type=:friends, start_node=MockNode.new, end_node=MockNode.new, props = {})
    @@id_counter ||= 0
    @@id_counter += 1
    @id = @@id_counter
    @rel_type = type
    @start_node = start_node
    @end_node = end_node
    @props = props
  end

  def _end_node
    @end_node
  end

  def _start_node
    @start_node
  end

  def getId
    @id
  end

  def set_property(k, v)
    @props[k.to_sym] = v
  end

  def get_property(k)
    @props[k.to_sym]
  end

  def has_property?(k)
    @props.include?(k.to_sym)
  end

  def get_other_node(not_this)
    not_this == _start_node ? _end_node : _start_node
  end

  def kind_of?(other)
    other == ::Java::OrgNeo4jGraphdb::Relationship || super
  end

  def property_keys
    @props.keys
  end

  alias_method :getEndNode, :_end_node
  alias_method :getStartNode, :_start_node
  alias_method :getType, :rel_type

end

Neo4j::Relationship.extend_java_class(MockRelationship)
