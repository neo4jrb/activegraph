module Neo4j::Aggregate

  class AggregateNode
    include Neo4j::NodeMixin
    include Neo4j::Aggregate::AggregateNodeMixin
  end


end