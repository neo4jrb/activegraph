include Java

require 'forwardable'

require 'neo4j/jars/neo4j-kernel-1.1.jar'
require 'neo4j/jars/geronimo-jta_1.1_spec-1.1.1.jar'
require 'neo4j/jars/lucene-core-2.9.2.jar'
require 'neo4j/jars/neo4j-index-1.1.jar'

require 'neo4j/version'
require 'neo4j/equal'
require 'neo4j/index'
require 'neo4j/relationship_traverser'
require 'neo4j/node_traverser'
require 'neo4j/property'
require 'neo4j/transaction'
require 'neo4j/relationship'
require 'neo4j/node'
require 'neo4j/class_mapping/node_mixin'
require 'neo4j/class_mapping/property_class_methods'
require 'neo4j/class_mapping/index_class_methods'

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

    def index(field, props)
      # the key is just the field if the node we want to index is not using the class mapping (NodeMixin)
      # otherwise we use both the class and the field as a key
      key = (props && props[:class]) ? "#{props[:class]}:#{field}" : field.to_s
      @fields[key] = props || {}
    end

    def rm_index(field)
      @fields.delete(field.to_s)
    end

    # void afterCommit(TransactionData data, T state)
    def before_commit(data)
      data.assigned_node_properties.each {|tx_data| update_index(tx_data) if trigger_update?(tx_data)}
    end

    def index_key_for(field, node)
      return field unless node.property?(:_classname)
      # get root node
      clazz = Neo4j::Node.to_class(node[:_classname])
      "#{clazz::ROOT_CLASS}:#{field}"
    end

    def trigger_update?(tx_data)
      key = index_key_for(tx_data.key, tx_data.entity)
      @fields[key]
    end

    def update_index(tx_data)
      node = tx_data.entity
      key = index_key_for(tx_data.key, node)

      # delete old index if it had a previous value
      node.rm_index(key) unless tx_data.previously_commited_value.nil?

      # add index
      node.index(key, node[tx_data.key])
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

    def index(field, props = nil)
      @lucene_sync.index(field, props)
    end

    def rm_index(field)
      @lucene_sync.rm_index(field)
      @lucene.remove_index(field.to_s)
    end
  end



end
