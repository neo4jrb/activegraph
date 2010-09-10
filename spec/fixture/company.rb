class Company
  include Neo4j::NodeMixin
  property :name
  property :revenue
  has_n :employees

  index :name
  index :revenue
end
