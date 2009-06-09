module Neo4j

  class TransactionsNode
    include NodeMixin

    # when a node is added to the transactions relationships
    # neo4j adds automatically a _next and _prev to added nodes
    # TransactionsNode.new
    # tx.transactions.each - return them as ordered
    has_list :transactions

    def add_tx(tx)
      TxNode.new
    end
  end


  class TxNode
    include NodeMixin

    property 
  end
end