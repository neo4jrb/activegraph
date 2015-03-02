module Neo4j::Core
  class Query
    # Creates a Neo4j::ActiveNode::Query::QueryProxy object that builds off of a Core::Query object.
    #
    # @param [Class] model An ActiveNode model to be used as the start of a new QueryuProxy chain
    # @param [Symbol] var The variable to be used to refer to the object from within the new QueryProxy
    # @param [Boolean] optional Indicate whether the new QueryProxy will use MATCH or OPTIONAL MATCH.
    # @return [Neo4j::ActiveNode::Query::QueryProxy] A QueryProxy object.
    def proxy_as(model, var, optional = false)
      # TODO: Discuss whether it's necessary to call `break` on the query or if this should be left to the user.
      Neo4j::ActiveNode::Query::QueryProxy.new(model, nil, node: var, optional: optional, starting_query: self, chain_level: @proxy_chain_level)
    end

    # Calls proxy_as with `optional` set true. This doesn't offer anything different from calling `proxy_as` directly but it may be more readable.
    def proxy_as_optional(model, var)
      proxy_as(model, var, true)
    end

    # For instances where you turn a QueryProxy into a Query and then back to a QueryProxy with `#proxy_as`
    attr_accessor :proxy_chain_level
  end
end
