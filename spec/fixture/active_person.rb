class ActivePerson < Neo4j::Model
  validates_presence_of :name
  property :name, :age
end