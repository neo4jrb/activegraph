require 'neo4j/config'
require 'neo4j/event_handler'
require 'neo4j/transaction'

module Neo4j
  # Wraps both Java Neo4j GraphDatabaseService and Lucene.
  # You can access the raw java neo4j and lucene db's with the <tt>graph</tt> and <tt>lucene</tt>
  # properties.
  #
  # This class is also responsible for checking if there is already a running neo4j database.
  # If one tries to start an already started database then a read only instance to neo4j will be used.
  #
  class Database
    attr_reader :graph, :lucene, :event_handler, :storage_path

    alias_method :index, :lucene # needed by cypher

    def initialize()
      @event_handler = EventHandler.new
    end

    def start #:nodoc:
      return if running?
      @running = true
      @storage_path = Config.storage_path


      if Config[:enable_remote_shell]
        Neo4j.logger.info("Enable remote shell at port #{Config[:enable_remote_shell]}")
        Neo4j.load_shell_jars
      end

      begin
        if self.class.locked?
          start_readonly_graph_db
        elsif Neo4j::Config['ha.db']
          start_ha_graph_db
          Neo4j.migrate!
        else
          start_local_graph_db
          Neo4j.migrate!
        end
      rescue
        @running = false
        raise
      end

      at_exit { shutdown }
    end

    def start_readonly_graph_db #:nodoc:
      Neo4j.logger.info "Starting Neo4j in readonly mode since the #{@storage_path} is locked"
      Neo4j.load_local_jars
      @graph = org.neo4j.kernel.EmbeddedReadOnlyGraphDatabase.new(@storage_path, Config.to_java_map)
      @lucene = @graph.index
    end

    def start_local_graph_db #:nodoc:
      Neo4j.logger.info "Starting local Neo4j using db #{@storage_path}"
      Neo4j.load_local_jars
      @graph = org.neo4j.kernel.EmbeddedGraphDatabase.new(@storage_path, Config.to_java_map)
      @graph.register_transaction_event_handler(@event_handler)
      @lucene = @graph.index
      @event_handler.neo4j_started(self)
    end

    # needed by cypher
    def getNodeById(id) #:nodoc:
      Neo4j::Node.load(id)
    end

    # needed by cypher
    def getRelationshipById(id) #:nodoc:
      Neo4j::Relationship.load(id)
    end

    def start_ha_graph_db
      Neo4j.logger.info "starting Neo4j in HA mode, machine id: #{Neo4j.config['ha.machine_id']} at #{Neo4j.config['ha.server']} db #{@storage_path}"
      Neo4j.load_ha_jars # those jars are only needed for the HighlyAvailableGraphDatabase
      Neo4j.load_online_backup if Neo4j.config[:online_backup_enabled]
      @graph = org.neo4j.kernel.HighlyAvailableGraphDatabase.new(@storage_path, Neo4j.config.to_java_map)
      @graph.register_transaction_event_handler(@event_handler)
      @lucene = @graph.index
      @event_handler.neo4j_started(self)
    end

    def start_external_db(external_graph_db)
      begin
        @running = true
        @graph = external_graph_db
        Neo4j.migrate!
        @graph.register_transaction_event_handler(@event_handler)
        @lucene = @graph.index #org.neo4j.index.impl.lucene.LuceneIndexProvider.new
        @event_handler.neo4j_started(self)
        Neo4j.logger.info("Started with external db")
      rescue
        @running = false
        raise
      end
    end

    def running? #:nodoc:
      @running
    end

    # Returns true if the neo4j db was started in read only mode.
    # This can occur if the database was locked (it was already one instance running).
    def read_only?
      @graph.isReadOnly
    end

    # check if the database is locked. A neo4j database is locked when the database is running.
    def self.locked?
      lock_file = File.join(Neo4j.config.storage_path, 'neostore')
      return false unless File.exist?(lock_file)
      rfile = java.io.RandomAccessFile.new(lock_file, 'rw')
      begin
        lock = rfile.getChannel.tryLock
        lock.release if lock
        return lock == nil # we got the lock, so that means it is not locked.
      rescue Exception => e
        return false
      end
    end

    def shutdown #:nodoc:
      if @running
        @graph.unregister_transaction_event_handler(@event_handler) unless read_only?
        @event_handler.neo4j_shutdown(self)
        @graph.shutdown
        @graph = nil
        @lucene = nil
        @running = false
        @neo4j_manager = nil
      end

    end


    def management(jmx_clazz) #:nodoc:
      @neo4j_manager ||= org.neo4j.management.Neo4jManager.new(@graph.get_management_bean(org.neo4j.jmx.Kernel.java_class))
      @neo4j_manager.getBean(jmx_clazz.java_class)
    end

    def begin_tx #:nodoc:
      @graph.begin_tx
    end


    def each_node #:nodoc:
      iter = @graph.all_nodes.iterator
      while (iter.hasNext)
        yield iter.next.wrapper
      end
    end

    def _each_node #:nodoc:
      iter = @graph.all_nodes.iterator
      while (iter.hasNext)
        yield iter.next
      end
    end

  end

end
