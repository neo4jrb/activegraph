include Java

require 'forwardable'

require 'neo4j/neo4j-kernel-1.1.jar'
require 'neo4j/geronimo-jta_1.1_spec-1.1.1.jar'
require 'neo4j/lucene-core-2.9.2.jar'
require 'neo4j/neo4j-index-1.1.jar'

require 'neo4j/node'
require 'neo4j/transaction'
require 'neo4j/version'
require 'neo4j/class_mapping/node_mixin'
require 'neo4j/class_mapping/property_class_methods'

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


  class LuceneSynchronizer
    include org.neo4j.graphdb.event.TransactionEventHandler

    def initialize
      @fields = {}
    end

    def after_commit(data, state)
      #puts "before commit"
    end

    def after_rollback(data, state)
      puts "rollback"
    end

    def index(field, props = {:fulltext => false})
      @fields[field.to_s] = props
    end

    def rm_index(field)
      @fields.delete(field.to_s)
    end

    # void afterCommit(TransactionData data, T state)
    def before_commit(data)
      data.assigned_node_properties.each {|tx_data| update_index(tx_data) if @fields[tx_data.key]}
    end

    def update_index(tx_data)
      node = tx_data.entity

      # delete old index if it had a previous value
      node.rm_index(tx_data.key) unless tx_data.previously_commited_value.nil?

      # add index
      node.index(tx_data.key)
    end
  end


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

    def index(field)
      @lucene_sync.index(field)
    end

    def rm_index(field)
      @lucene_sync.rm_index(field)
      @lucene.remove_index(field.to_s)
    end
  end



end
