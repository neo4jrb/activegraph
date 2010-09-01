module Neo4j::Aggregate

  class PropsAggregate
    include Neo4j::NodeMixin
    include Neo4j::Aggregate::PropsAggregateMixin
  end

end