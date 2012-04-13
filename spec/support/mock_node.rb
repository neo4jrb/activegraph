class MockNode
  attr_reader :props

  def initialize(props={})
    @@id_counter ||= 0
    @@id_counter += 1
    @id = @@id_counter
    @props = props.clone
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

  def kind_of?(other)
    other == Java::OrgNeo4jGraphdb::Node || super
  end

  def property_keys
    @props.keys
  end
end

Neo4j::Node.extend_java_class(MockNode)

class MockNode
  extend Neo4j::Core::Wrapper
end
