module Neo4j::Core
  class Query
    # Creates a Neo4j::ActiveNode::Query::QueryProxy object that builds off of a Core::Query object.
    #
    # @param [Class] model An ActiveNode model to be used as the start of a new QueryuProxy chain
    # @param [Symbol] var The variable to be used to refer to the object from within the new QueryProxy
    # @return [Neo4j::ActiveNode::Query::QueryProxy] A QueryProxy object.
    def proxy_as(model, var)
      # TODO: Discuss whether it's necessary to call `break` on the query or if this should be left to the user.
      Neo4j::ActiveNode::Query::QueryProxy.new(model, nil, { starting_query: self.break, node: var })
    end
  end
end
