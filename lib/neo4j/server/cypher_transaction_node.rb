module Neo4j::Server
  class CypherTransactionNode < Neo4j::Node
    def delegator=(node)
      @delegator = node
    end

    def delegator
      @delegator
    end
  end
end