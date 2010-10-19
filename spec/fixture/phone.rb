# forward declaration
class Phone
  include Neo4j::NodeMixin
end

class Person
  include Neo4j::NodeMixin
  has_one(:home_phone).to(Phone)
end

class Phone
  include Neo4j::NodeMixin
  property :phone_number
  has_one(:person).from(Person, :home_phone)

  index :phone_number, :via => :person, :type => :exact
end