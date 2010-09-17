class Company
  include Neo4j::NodeMixin
#  include Neo4j::Index
  property :name
  property :revenue
  has_n :employees

  index :name, :type => :fulltext
  index :revenue
end
