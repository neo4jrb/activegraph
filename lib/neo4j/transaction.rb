module Neo4j
  class Transaction
    def self.new(instance = Neo4j.db)
      Thread.current[id_for_instance(instance)] = instance.begin_tx
    end

    def self.finish(instance = Neo4j.db)
      tx = Thread.current[id_for_instance(instance)]
      return unless tx
      tx.success
      tx.finish
    end

    def self.id_for_instance(instance)
      "tx#{instance.object_id}".to_sym
    end

    # Runs a block in a Neo4j transaction
    #
    # Many operations on neo requires an transaction. You will get much better performance if
    # one transaction is wrapped around several neo operation instead of running one transaction per
    # neo operation.
    # If one transaction is already running then a 'placebo' transaction will be created.
    # Performing a finish on a placebo transaction will not finish the 'real' transaction.
    #
    # ==== Params
    # ::yield:: the block to be performed in one transaction
    #
    # ==== Examples
    #  include 'neo4j'
    #
    #  Neo4j::Transaction.run {
    #    node = PersonNode.new
    #  }
    #
    # You have also access to transaction object
    #
    #   Neo4j::Transaction.run { |t|
    #     # something failed
    #     t.failure # will cause a rollback
    #   }

    # If an exception occurs inside the block the transaction will rollback automatically
    #
    # ==== Returns
    # The value of the evaluated provided block
    #
    def self.run # :yield: block that will be executed in a transaction
      raise ArgumentError.new("Expected a block to run in Transaction.run") unless block_given?

      begin
        tx = Neo4j::Transaction.new
        ret = yield tx
        tx.success
      rescue Exception
        tx.failure unless tx.nil?
        raise
      ensure
        tx.finish unless tx.nil?
      end
      ret
    end
  end
end