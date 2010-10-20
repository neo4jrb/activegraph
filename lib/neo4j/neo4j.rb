module Neo4j

  class << self


    # Start Neo4j using the default database.
    # This is usally not required since the database will be started automatically when it is used.
    #
    def start
      db = default_db
      db.start unless db.running?
    end


    # sets the default database to use
    def default_db=(my_db)
      @db = my_db
    end

    # Returns default database. Creates a new one if it does not exist, but does not start it.
    def default_db
      @db ||= Database.new
    end

    # Returns a started db instance. Starts it if's not running.
    def started_db
      db = default_db
      db.start unless db.running?
      db
    end


    # Returns an unstarted db instance
    # this is typically used for configuring the database, which must sometimes
    # be done before the database is started
    # if the database was already started an excetion will be raised
    def unstarted_db
      @db ||= Database.new
      raise "database was already started" if @db.running?
      @db
    end

    # returns true if the database is running
    def running?
      @db && @db.running?
    end


    def shutdown(this_db = @db)
      this_db.shutdown if this_db
    end

    def ref_node(this_db = self.started_db)
      this_db.graph.reference_node
    end

    # Returns an Enumerable object for all nodes in the database
    def all_nodes(this_db = self.started_db)
      Enumerator.new(this_db, :each_node)
    end

    # Same as #all_nodes but does not return wrapped nodes.
    def _all_nodes(this_db = self.started_db)
      Enumerator.new(this_db, :_each_node)
    end

    def event_handler(this_db = default_db)
      this_db.event_handler
    end
  end
end
