module Neo4j
  class Database
    attr_reader :config, :graph, :lucene, :lucene_fulltext

    def initialize(config)
      @config = config
      @graph = org.neo4j.kernel.EmbeddedGraphDatabase.new(@config[:storage_path])
      @lucene =  org.neo4j.index.lucene.LuceneIndexService.new(@graph)
      @lucene_sync = LuceneSynchronizer.new
      @graph.register_transaction_event_handler(@lucene_sync)
    end


    def shutdown
      @graph.shutdown
      @lucene.shutdown
    end

    def begin_tx
      @graph.begin_tx
    end

    def index(field, props = nil)
      @lucene_sync.index(field, props)
    end

    def rm_index(field)
      @lucene_sync.rm_index(field)
      @lucene.remove_index(field.to_s)
    end
  end

end