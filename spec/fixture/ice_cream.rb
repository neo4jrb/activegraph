class Ingredient < Neo4j::Rails::Model
  property :name
end

class IceCream < Neo4j::Rails::Model
  property :flavour, :index => :exact
  has_n(:ingredients).to(Ingredient)
  validates_presence_of :flavour
end

