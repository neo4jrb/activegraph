class Ingredient < Neo4j::RailsNode
  property :name
end

class IceCream < Neo4j::RailsNode
  property :flavour, :index => :exact
  has_n(:ingredients).to(Ingredient)
  validates_presence_of :flavour
end

