include Java

require 'neo4j/neo4j-kernel-1.1.jar'
require 'neo4j/geronimo-jta_1.1_spec-1.1.1.jar'
require 'neo4j/lucene-core-2.9.2.jar'
require 'neo4j/neo4j-index-1.1.jar'

require 'neo4j/node'
require 'neo4j/transaction'
require 'neo4j/version'

module Neo4j

  DEFAULT_CONFIG = {:storage_path => 'tmp/neo4j'}

  class << self

    def start(new_instance=nil)
      @instance = new_instance if new_instance
      instance
    end

    def db
      @db ||= Database.new(config)
    end

    def config()
      @config ||= DEFAULT_CONFIG.clone
    end

    def shutdown(this_db = @db)
      this_db.shutdown if this_db
      @db = nil if this_db == @db
    end
  end

  class Database
    attr_reader :config, :graph, :lucene, :lucene_fulltext

    def initialize(config)
      @config = config
      @graph = org.neo4j.kernel.EmbeddedGraphDatabase.new(@config[:storage_path])
      @lucene =  org.neo4j.index.lucene.LuceneIndexService.new(@graph)
    end


    def shutdown
      @graph.shutdown
      @lucene.shutdown
    end

    def begin_tx
      @graph.begin_tx
    end
  end



end
