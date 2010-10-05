class Friend
  include Neo4j::RelationshipMixin

  property :since
  index :since
end