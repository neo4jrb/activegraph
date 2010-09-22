class Person
  include Neo4j::NodeMixin
  property :name
  property :city

  has_n :friends
  has_one :address

end


