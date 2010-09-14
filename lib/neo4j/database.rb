module Neo4j
  class Database
    attr_reader :graph, :lucene, :lucene_fulltext, :event_handler

    def initialize()
      @event_handler = EventHandler.new
      @lucene_sync   = LuceneSynchronizer.new
    end


    def start
      @running = true
      @graph = org.neo4j.kernel.EmbeddedGraphDatabase.new(Config[:storage_path])
      @lucene =  org.neo4j.index.lucene.LuceneIndexService.new(@graph)
      @graph.register_transaction_event_handler(@lucene_sync)
      @graph.register_transaction_event_handler(@event_handler)
      @event_handler.neo4j_started(self)
    end

    def shutdown
      puts "SHUT DOWN #{caller.inspect}"
      @running = false
      @graph.unregister_transaction_event_handler(@lucene_sync)
      @graph.unregister_transaction_event_handler(@event_handler)
      @event_handler.neo4j_shutdown(self)
      @graph.shutdown
      @lucene.shutdown
    end

    def running?
      @running
    end

    def begin_tx
      @graph.begin_tx
    end

    def find(field, query, props)
       @lucene_sync.find(@lucene, field, query, props)
    end

    def index(field, props)
      @lucene_sync.index(field, props)
    end

    def rm_index(field, props)
      @lucene_sync.rm_index(@lucene, field, props)
    end

    def each_node
      iter = @graph.all_nodes.iterator
      while (iter.hasNext)
        yield Node.load_wrapper(iter.next)
      end
    end

  end

end
