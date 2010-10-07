class Avator < Neo4j::Model
  property :icon
end

class Member < Neo4j::Model
  has_one(:avatar).to(Avator)
  accepts_nested_attributes_for :avatar, :allow_destroy => true
end