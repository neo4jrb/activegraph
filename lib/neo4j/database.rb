module Neo4j
  # Wraps both Java Neo4j GraphDatabaseService and Lucene.
  # You can access the raw java neo4j and lucene db's with the <tt>graph</tt> and <tt>lucene</tt>
  # properties.
  #
  # This class is also responsible for checking if there is already a running neo4j database.
  # If one tries to start an already started database then a read only instance to neo4j will be used.
  #
  class Database
    attr_reader :graph, :lucene, :event_handler

    def initialize()
      @event_handler = EventHandler.new
    end

    def start #:nodoc:
      return if running?
      @running = true
      
      if self.class.locked?
        start_readonly_graph_db
      else
        start_local_graph_db
      end

      at_exit { shutdown }
    end

    def start_readonly_graph_db #:nodoc:
      puts "Starting Neo4j in readonly mode since the #{Config[:storage_path]} is locked"
      @graph = org.neo4j.kernel.EmbeddedReadOnlyGraphDatabase.new(Config[:storage_path])
    end

    def start_local_graph_db #:nodoc:
      @graph = org.neo4j.kernel.EmbeddedGraphDatabase.new(Config[:storage_path])
      @graph.register_transaction_event_handler(@event_handler)
      @lucene =  @graph.index #org.neo4j.index.impl.lucene.LuceneIndexProvider.new
      @event_handler.neo4j_started(self)
    end

    def running? #:nodoc:
      @running
    end

    # Returns true if the neo4j db was started in read only mode.
    # This can occur if the database was locked (it was already one instance running).
    def read_only?
      @graph.isReadOnly
    end

    # check if the database is locked. A neo4j database is locked when there is running.
    def self.locked?
      lock_file = File.join(::Neo4j::Config[:storage_path], 'neostore')
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
        @graph  = nil
        @lucene = nil
        @running = false
      end

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
