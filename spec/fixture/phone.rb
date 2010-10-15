# forward declaration
class Person
  include Neo4j::NodeMixin
end

class Phone
  include Neo4j::NodeMixin
  property :phone
  index :phone, :indexer => Person, :via => proc{|node| node.incoming(:phone).first} # TODO should return an enumeration ?
end