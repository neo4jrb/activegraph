module Neo4j::Aggregate

  class NodeAggregate
    include Neo4j::NodeMixin
    include Neo4j::Aggregate::NodeAggregateMixin
  end

end