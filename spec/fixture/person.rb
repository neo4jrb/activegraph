class Person
  include Neo4j::NodeMixin
  property :name
  property :city

  has_n :friends
end
