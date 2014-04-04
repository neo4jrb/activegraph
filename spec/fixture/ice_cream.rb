class Ingredient < Neo4j::Rails::Model
  property :name
end

class IceCream < Neo4j::Rails::Model
  property :flavour, :index => :exact
  has_n(:ingredients).to(Ingredient)
  validates_presence_of :flavour
end

class IceCreamStamp < Neo4j::Rails::Model
  property :flavour, :index => :exact
  property :created_at, type: DateTime
  property :updated_at, type: DateTime
  has_n(:ingredients).to(Ingredient)
  validates_presence_of :flavour
end
