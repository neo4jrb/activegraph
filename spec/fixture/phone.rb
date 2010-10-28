# forward declaration
#class Person
#  include Neo4j::NodeMixin
#end

class Phone
  include Neo4j::NodeMixin
end

class Company
  include Neo4j::NodeMixin
end

class Person
  include Neo4j::NodeMixin

  has_one(:home_phone).to(Phone)

  property :name
  property :city

  has_n :friends
  has_n(:friend_by).from(:friends)
  has_one :address
  has_n(:employed_by).from(Company, :employees)
  index :name

end


class Phone
  include Neo4j::NodeMixin
  property :phone_number
  has_one(:person).from(Person, :home_phone)

  index :phone_number, :via => :person, :type => :exact
end
