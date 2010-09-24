module Neo4j
  class Database
    attr_reader :graph, :lucene, :event_handler

    def initialize()
      @event_handler = EventHandler.new
    end


    def start
      @running = true
      @graph = org.neo4j.kernel.EmbeddedGraphDatabase.new(Config[:storage_path])
      @lucene = org.neo4j.index.impl.lucene.LuceneIndexProvider.new(@graph)
      @graph.register_transaction_event_handler(@event_handler)
      @event_handler.neo4j_started(self)
      at_exit { shutdown }
    end

    def shutdown
      @running = false
      @graph.unregister_transaction_event_handler(@event_handler)
      @event_handler.neo4j_shutdown(self)
      @graph.shutdown
    end

    def running?
      @running
    end

    def begin_tx
      @graph.begin_tx
    end


    def each_node
      iter = @graph.all_nodes.iterator
      while (iter.hasNext)
        yield Node.load_wrapper(iter.next)
      end
    end

  end

end
