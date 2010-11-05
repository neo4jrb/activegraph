class Vehicle
  include Neo4j::NodeMixin
  index :wheels
  property :built_date, :type => Date
  property :name, :type => String
  property :weight, :type => Float
  index :weight
  index :name
end

class Car < Vehicle
  node_indexer Vehicle # use the same indexer as Vehicle, get index on wheels
  index :brand, :type => :fulltext
  index :colour
end
