module Neo4j::Aggregate
  class AggregateEachNode
    include Neo4j::NodeMixin
    include Neo4j::Aggregate::AggregateEachNodeMixin
  end
end