module Neo4j

  # Starts neo unless it is not already started.
  # Before using neo it has to be started and the location of the Neo database on the filesystem must
  # have been configured, Neo4j::Config[:storage_path].
  #
  # ==== Examples
  # Neo4j::Config[:storage_path] = '/var/neo4j-db'
  # Neo4j.start
  #
  # ==== Returns
  # Nil
  #
  # :api: public
  def self.start
    return if running?
    at_exit do
      Neo4j.stop
    end
    @neo = org.neo4j.api.core.EmbeddedNeo.new(Neo4j::Config[:storage_path])
    @ref_node = Neo4j::Transaction.run do
      ReferenceNode.new(@neo.getReferenceNode())
    end

    Neo4j::Transaction.run do
      Neo4j.event_handler.neo_started(self)
    end
    nil
  end

  # Return the org.neo4j.api.core.EmbeddedNeo
  #
  #
  def self.instance
    start unless running?
    @neo
  end

  # Stops the current instance unless it is not started.
  # This must be done in order to avoid corrupt neo database.
  # 
  # :api: public
  def self.stop
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
  # :api: public
  def self.running?
    !@neo.nil?
  end


  # Create a Neo4j::Node
  # This is the same as Neo4j::Node.new
  #
  def self.create_node
    instance.createNode
  end

  # Return a Neo4j node.
  #
  # ==== Parameters
  # node_id<String, to_i>:: the unique neo id for one node
  # raw<true|false(default)> :: if the raw Java node object should be returned or the Ruby wrapped node. 
  #
  # ==== Returns
  # The node object or nil if not found
  # 
  # :api: public
  def self.load_node(node_id, raw = false)
    neo_node = @neo.getNodeById(node_id.to_i)
    if (raw)
      neo_node
    else
      neo_node.wrapper
    end
  rescue org.neo4j.api.core.NotFoundException
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
  # :api: public
  def self.load_rel(rel_id, raw = false)
    neo_rel = @neo.getRelationshipById(rel_id.to_i)
    if (raw)
      neo_rel
    else
      neo_rel.wrapper
    end
  rescue org.neo4j.api.core.NotFoundException
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
# :api: public
  def self.all_nodes(raw = false)
    iter = instance.all_nodes.iterator
    while (iter.hasNext)
      yield load_node(iter.next.neo_id, raw)
    end
  end

# Returns the reference node, which is a "starting point" in the node space.
#
# Usually, a client attaches relationships to this node that leads into various parts of the node space.
# For more information about common node space organizational patterns, see the design guide at http://neo4j.org/doc.
#
# ==== Returns
# The the ReferenceNode
#
# :api: public
  def self.ref_node
    @ref_node
  end


# Returns an event handler.
# This event handler can be used for listen to event such as when the Neo4j is started/stopped or
# when a node is created/deleted, a property/relationship is changed.
#
# ==== Returns
# a Neo4j::EventHandler instance
#
# :api: public
  def self.event_handler
    @event_handler ||= EventHandler.new
  end


  def self.number_of_nodes_in_use
    instance.getConfig().getNeoModule().getNodeManager().getNumberOfIdsInUse(org.neo4j.api.core.Node.java_class)
  end

  def self.number_of_relationships_in_use
    instance.getConfig().getNeoModule().getNodeManager().getNumberOfIdsInUse(org.neo4j.api.core.Relationship.java_class)
  end

  def self.number_of_properties_in_use
    instance.getConfig().getNeoModule().getNodeManager().getNumberOfIdsInUse(org.neo4j.impl.nioneo.store.PropertyStore.java_class)
  end

# Prints some info about the database
  def self.info
    puts "Neo4j version:                  #{Neo4j::VERSION}"
    puts "Neo4j db running                #{self.running?}"
    puts "number_of_nodes_in_use:         #{self.number_of_nodes_in_use}"
    puts "number_of_relationships_in_use: #{self.number_of_relationships_in_use}"
    puts "number_of_properties_in_use:    #{self.number_of_properties_in_use}"
    puts "neo db storage location:        #{Neo4j::Config[:storage_path]}"
    puts "lucene index storage location:  #{Lucene::Config[:storage_path]}"
    puts "keep lucene index in memory:    #{!Lucene::Config[:store_on_file]}"
  end

end

