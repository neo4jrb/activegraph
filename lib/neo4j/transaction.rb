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
  end
end