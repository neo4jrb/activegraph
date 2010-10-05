class NodeWithInitializer
  include Neo4j::NodeMixin
  property :name
  property :city

  def init_on_create(name, city)
    self.name = name
    self.city = city
  end

end