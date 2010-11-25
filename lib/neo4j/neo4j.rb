# = Neo4j
#
# The Neo4j modules is used to interact with an Neo4j Database instance.
# You can for example start and stop an instance and list all the nodes that exist in the database.
#
# === Starting and Stopping Neo4j
# You don't normally need to start the Neo4j database since it will be automatically started when needed.
# Before the database is started you should configure where the database is stored, see Neo4j::Config.
#
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

    def read_only?
      @db && @db.graph && @db.graph.read_only?
    end
    
    # Returns a started db instance. Starts it's not running.
    def started_db
      db = default_db
      db.start unless db.running?
      db
    end


    # Returns an unstarted db instance
    #
    # This is typically used for configuring the database, which must sometimes
    # be done before the database is started
    # if the database was already started an exception will be raised
    def unstarted_db
      @db ||= Database.new
      raise "database was already started" if @db.running?
      @db
    end

    # returns true if the database is running
    def running?
      @db && @db.running?
    end


    # Stops this database
    # There are Ruby hooks that will do this automatically for you.
    #
    def shutdown(this_db = @db)
      this_db.shutdown if this_db
    end

    # Returns the reference node, which is a "starting point" in the node space.
    #
    # Usually, a client attaches relationships to this node that leads into various parts of the node space.
    # For more information about common node space organizational patterns, see the design guide at http://wiki.neo4j.org/content/Design_Guide
    #
    def ref_node(this_db = self.started_db)
      this_db.graph.reference_node
    end

    # Returns an Enumerable object for all nodes in the database
    def all_nodes(this_db = self.started_db)
      Enumerator.new(this_db, :each_node)
    end

    # Same as #all_nodes but does not return wrapped nodes but instead raw java node objects.
    def _all_nodes(this_db = self.started_db)
      Enumerator.new(this_db, :_each_node)
    end

    # Returns the Neo4j::EventHandler
    #
    def event_handler(this_db = default_db)
      this_db.event_handler
    end
    
    # Ruby to Java type converters
    def converters
    	Neo4j::Config[:converters] || {}
    end
  end
end
