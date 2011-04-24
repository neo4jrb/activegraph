# external neo4j dependencies
require 'neo4j/config'
require 'neo4j/database'

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
    # ==== Parameters
    # config_file :: (optionally) if this is nil or not given use the Neo4j::Config, otherwise setup the Neo4j::Config file using the provided YAML configuration file.
    #
    def start(config_file=nil)
      Neo4j.config.default_file = config_file if config_file
      db.start unless db.running?
    end


    # Sets the Neo4j::Database instance to use
    # An Neo4j::Database instance wraps both the Neo4j Database and Lucene Database.
    def db=(my_db)
      @db = my_db
    end

    # Returns the database holding references to both the Neo4j Graph Database and the Lucene Database.
    # Creates a new one if it does not exist, but does not start it.
    def db
      @db ||= Database.new
    end

    def read_only?
      @db && @db.graph && @db.graph.read_only?
    end
    
    # Returns a started db instance. Starts it's not running.
    def started_db
      db.start unless db.running?
      db
    end

    # Returns the current storage path of a running neo4j database.
    # If the database is not running it returns nil.
    def storage_path
      return nil unless db.running?
      db.storage_path
    end

    # Returns the Neo4j::Config class
    # Same as typing; Neo4j::Config
    def config
      Neo4j::Config
    end

    # Returns the logger used by neo4j.
    # If not specified (with Neo4j.logger=) it will use the standard Ruby logger.
    # You can change standard logger threshold by configuration :logger_level.
    #
    # You can also specify which logger class should take care of logging with the
    # :logger configuration.
    #
    # ==== Example
    #
    #  Neo4j::Config[:logger] = Logger.new(STDOUT)
    #  Neo4j::Config[:logger_level] = Logger::ERROR
    #
    def logger
      @logger ||= Neo4j::Config[:logger] || default_logger
    end

    # Sets which logger should be used.
    # If this this is not called then the standard Ruby logger will be used.
    def logger=(logger)
      @logger = logger
    end

    def default_logger #:nodoc:
      require 'logger'
      logger = Logger.new(STDOUT)
      logger.sev_threshold = Neo4j::Config[:logger_level] || Logger::INFO
      logger
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

    # Returns a Management JMX Bean.
    #
    # Notice that this information is also provided by the jconsole Java tool, check http://wiki.neo4j.org/content/Monitoring_and_Deployment
    # and http://docs.neo4j.org/chunked/milestone/operations-monitoring.html
    #
    # By default it returns the Primitivies JMX Bean that can be used to find number of nodes in use.
    #
    # ==== Example Neo4j Primititives
    #
    #   Neo4j.management.get_number_of_node_ids_in_use
    #   Neo4j.management.getNumberOfPropertyIdsInUse
    #   Neo4j.management.getNumberOfRelationshipIdsInUse
    #   Neo4j.management.get_number_of_relationship_type_ids_in_use
    #
    # ==== Example Neo4j HA Cluster Info
    #
    # Neo4j.management(org.neo4j.management.HighAvailability).isMaster
    #
    # ==== Arguments
    #
    # jmx_clazz :: http://api.neo4j.org/current/org/neo4j/management/package-summary.html
    # this_db :: default currently runnig instance or a newly started neo4j db instance
    #
    def management(jmx_clazz = org.neo4j.jmx.Primitives, this_db = self.started_db)
      this_db.management(jmx_clazz)
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
    def event_handler(this_db = db)
      this_db.event_handler
    end
    
  end
end
