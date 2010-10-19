# forward declaration
class Company
end

class Person
  include Neo4j::NodeMixin
  property :name
  property :city

  has_n :friends
  has_one :address
  has_n(:employed_by).from(Company, :employees)
  index :name
end


