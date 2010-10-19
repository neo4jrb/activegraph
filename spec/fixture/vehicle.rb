class Vehicle
  include Neo4j::NodeMixin
  index :wheels
end

class Car < Vehicle
  node_indexer Vehicle # use the same indexer as Vehicle, get index on wheels
  index :brand, :type => :fulltext
  index :colour
end
