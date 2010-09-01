module Neo4j

  class << self
    extend Forwardable

    ##
    # Returns the current version of the database.
    # This version has been set by running one or more migrations.
    # The version is stored on the reference node, with property 'db_version'
    # (Delegates to the Reference Node that includes the MigrationMixin.)
    #
    # === See Also
    # Neo4j::MigrationMixin#db_version
    #
    # :singleton-method: db_version

    ##
    # Force Neo4j.rb to perform migrations
    #
    # === See Also
    # Neo4j::MigrationMixin#migrate!
    #
    # :singleton-method: migrate!

    ##
    # Specifies a single migration.
    #
    # === Example
    # Notice that the reference node is the context in the up and down blocks.
    #
    #   Neo4j.migration 1, :create_articles do
    #    up do
    #      rels.outgoing(:colours) << Neo4j.new :colour => 'red'  << Neo4j.new :colour => 'blue'
    #    end
    #    down do
    #      rels.outgoing(:colours).each {|n| n.del }
    #    end
    #  end
    #
    # === See Also
    # Neo4j::MigrationMixin::ClassMethods#migration
    # Neo4j::ReferenceNode
    #
    # :singleton-method: migration

    ##
    # Returns all migrations that has been defined.
    #
    # === See Also
    # Neo4j::MigrationMixin::ClassMethods#migrations
    #
    # :singleton-method: migrations

    def_delegators :@ref_node, :db_version, :migrate!
    def_delegators Neo4j::ReferenceNode, :migration, :migrations



    # Starts neo4j unless it is not already started.
    # Before using neo4j it has to be started and the location of the Neo database on the file system must
    # have been configured, Neo4j::Config[:storage_path]. You do not have to call this method since
    # neo4j will be started automatically when needed.
    # Registers an at_exit handler that stops neo4j (see Neo4j::stop)
    #
    # === Parameters
    # neo_instance:: optional, an instance of org.neo4j.graphdb.GraphDatabaseService
    #
    # === Examples
    #   Neo4j::Config[:storage_path] = '/var/neo4j-db'
    #   Neo4j.start
    #
    # === Returns
    # nil
    #
    def start(neo_instance=nil)
      return if running?
      at_exit do
        Neo4j.stop
      end
      @neo = neo_instance || org.neo4j.kernel.EmbeddedGraphDatabase.new(Neo4j::Config[:storage_path])
      @ref_node = Neo4j::Transaction.run do
        ReferenceNode.new(@neo.getReferenceNode())
      end

      Neo4j::Transaction.run do
        Neo4j.event_handler.neo_started(self)
      end

      Neo4j::Transaction.run { @ref_node.migrate!}
      nil
    end

    # Return the org.neo4j.kernel.EmbeddedGraphDatabase
    #
    #
    def instance
      start unless running?
      @neo
    end

    # Stops the current instance unless it is not started.
    #
    def stop
      if running?
        Neo4j::Transaction.finish # just in case
        @neo.shutdown
        Neo4j.event_handler.neo_stopped(self)
      end
      @neo = nil
    end

    #
    # Returns true if neo4j is running
    #
    def running?
      !@neo.nil?
    end


    # Create a Neo4j::Node
    # This is the same as Neo4j::Node.new.
    # All nodes are created by this method
    def create_node(props = {}) # :nodoc:
      node = instance.createNode
      props.each_pair{|k,v| node[k] = v}
      node
    end

    # Creates a new Relationship
    # All relationships are created by this method.
    def create_rel(type, from_node, to_node, props = {}) # :nodoc:
      rel = from_node.add_rel(type, to_node)
      props.each_pair {|k,v| rel[k] = v}
      rel
    end

    # Return a Neo4j node.
    #
    # ==== Parameters
    # node_id:: the unique neo id for one node, should respond to 'to_i'
    # raw:: if the raw Java node object should be returned or the Ruby wrapped node, default false.
    #
    # ==== Returns
    # The node object or nil if not found
    #
    def load_node(node_id, raw = false)
      neo_node = @neo.getNodeById(node_id.to_i)
      if (raw)
        neo_node
       else
        neo_node.wrapper
      end
    rescue org.neo4j.graphdb.NotFoundException
      nil
    end


    # Return a Neo4j relationship.
    #
    # ==== Parameters
    # rel_id<String, to_i>:: the unique neo id for one node
    # raw<true|false(default)> :: if the raw Java relationship object should be returned or the Ruby wrapped node.
    #
    # ==== Returns
    # The node object or nil if not found
    #
    def load_rel(rel_id, raw = false)
      neo_rel = @neo.getRelationshipById(rel_id.to_i)
      if (raw)
        neo_rel
      else
        neo_rel.wrapper
      end
    rescue org.neo4j.graphdb.NotFoundException
      nil
    end

    # Returns all nodes in the node space.
    # Expects a block that will be yield.
    #
    # ==== Parameters
    # raw<true|false(default)> :: if the raw Java node object should be returned or the Ruby wrapped node.
    #
    # ==== Example
    #
    #   Neo4j.all_nodes{|node| puts "Node id ${node.neo_id"}
    #
    def all_nodes(raw = false)
      iter = instance.all_nodes.iterator
      while (iter.hasNext)
        id = iter.next.neo_id
        yield load_node(id, raw)
      end
    end

    # Returns the reference node, which is a "starting point" in the node space.
    #
    # Usually, a client attaches relationships to this node that leads into various parts of the node space.
    # For more information about common node space organizational patterns, see the design guide at http://neo4j.org/doc.
    #
    # ==== Returns
    # The the Neo4j::ReferenceNode
    #
    def ref_node
      @ref_node
    end


    # Returns an event handler.
    # This event handler can be used for listen to event such as when the Neo4j is started/stopped or
    # when a node is created/deleted, a property/relationship is changed.
    #
    # ==== Returns
    # a Neo4j::EventHandler instance
    #
    def event_handler
      @event_handler ||= EventHandler.new
    end


    def number_of_nodes_in_use
      instance.getConfig().getNeoModule().getNodeManager().getNumberOfIdsInUse(org.neo4j.graphdb.Node.java_class)
    end

    def number_of_relationships_in_use
      instance.getConfig().getNeoModule().getNodeManager().getNumberOfIdsInUse(org.neo4j.graphdb.Relationship.java_class)
    end

    def number_of_properties_in_use
      instance.getConfig().getNeoModule().getNodeManager().getNumberOfIdsInUse(org.neo4j.kernel.impl.nioneo.store.PropertyStore.java_class)
    end

    # Prints some info about the database
    def info
      puts "Neo4j version:                  #{Neo4j::VERSION}"
      puts "Neo4j db running                #{running?}"
      puts "number_of_nodes_in_use:         #{number_of_nodes_in_use}"
      puts "number_of_relationships_in_use: #{number_of_relationships_in_use}"
      puts "number_of_properties_in_use:    #{number_of_properties_in_use}"
      puts "neo db storage location:        #{Neo4j::Config[:storage_path]}"
      puts "lucene index storage location:  #{Lucene::Config[:storage_path]}"
      puts "keep lucene index in memory:    #{!Lucene::Config[:store_on_file]}"
    end

  end
end

