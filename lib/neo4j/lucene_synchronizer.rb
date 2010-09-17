module Neo4j
  class LuceneSynchronizer # :nodoc:
    include org.neo4j.graphdb.event.TransactionEventHandler

    attr_accessor :provider

    def initialize
      @indexers = []
    end

    def after_commit(*)
      #puts "before commit"
    end

    def after_rollback(*)
    end

    def before_commit(tx_data)
      tx_data.assigned_node_properties.each do |p_entry|
        @indexers.each {|indexer| indexer.update(p_entry) if indexer.trigger?(p_entry)}
      end

      # TODO

#      tx_data.assigned_node_properties.each do |p_entry|
#        @indexers.each {|indexer| indexer.remove(p_entry) if indexer.trigger?(p_entry)}
#      end
    end

    def register(indexer)
      raise "already registered indexer #{indexer}" if registered?(indexer)
      @indexers << indexer
    end

    def registered?(indexer)
       @indexers.include?(indexer)
    end
  end
end