require 'drb'
require 'socket'

module Neo4j
  class Database #:nodoc:
    attr_reader :graph, :lucene, :event_handler

    def initialize()
      @event_handler = EventHandler.new
    end

    def start
      return if running?
      @running = true
      
      if self.class.locked?
        start_readonly_graph_db
      else
        start_local_graph_db
      end

      at_exit { shutdown }
    end

    def start_readonly_graph_db
      puts "Starting Neo4j in readonly mode since the #{Config[:storage_path]} is locked"
      @graph = org.neo4j.kernel.EmbeddedReadOnlyGraphDatabase.new(Config[:storage_path])
    end

    def start_local_graph_db
      @graph = org.neo4j.kernel.EmbeddedGraphDatabase.new(Config[:storage_path])
      @graph.register_transaction_event_handler(@event_handler)
      @lucene =  @graph.index #org.neo4j.index.impl.lucene.LuceneIndexProvider.new
      @event_handler.neo4j_started(self)
    end

    def running?
      @running
    end

    def read_only?
      @graph.isReadOnly
    end

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
    
    def shutdown
      if @running
        @graph.unregister_transaction_event_handler(@event_handler) unless read_only?
        @event_handler.neo4j_shutdown(self)
        @graph.shutdown
        @graph  = nil
        @lucene = nil
        @running = false
      end

    end

    def begin_tx
      @graph.begin_tx
    end


    def each_node
      iter = @graph.all_nodes.iterator
      while (iter.hasNext)
        yield iter.next.wrapper
      end
    end

    def _each_node
      iter = @graph.all_nodes.iterator
      while (iter.hasNext)
        yield iter.next
      end
    end

  end

end
