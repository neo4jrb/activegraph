module Neo4j


  # The relationship class between TxNodes
  class TxNodeRelationship
    include Neo4j::RelationshipMixin
  end

  # This nodes listen for all events like node nodes created/deleted or
  # if a property/relationship has changed. When a event is triggered it
  #
  class TxNodeList
    include Neo4j::NodeMixin

    has_list(:tx_nodes).relationship(TxNodeRelationship)

    def on_node_created(node)
      tx = TxNodeCreated.new
      uuid = Neo4j.create_uuid
      node[:uuid] = uuid # TODO should use a better UUID
      tx[:tracked_neo_id] = node.neo_id
      tx[:tracked_classname] = node.class.to_s unless node.kind_of?(org.neo4j.api.core.Node)
      tx[:created] = true
      tx[:uuid] = uuid
      tx_nodes << tx
    end

    def on_node_deleted(node)
      tx = TxNode.new
      tx[:uuid] = node[:uuid]
      tx[:deleted] = true
      tx[:tracked_classname] = node.class.to_s unless node.kind_of?(org.neo4j.api.core.Node)
      tx_nodes << tx
    end


    def on_tx_finished(tx)
      return if self.tx_nodes.empty? # nothing yet commited
      last_commited_node = self.tx_nodes.first
      last_commited_node[:tx_finished] = true
    end

    def on_property_changed(node, key, old_value, new_value)
      return if "uuid" == key.to_s # do not track uuid
      tx = TxNode.new
      tx[:uuid] = node[:uuid]
      tx[:property_changed] = true
      tx[:tracked_neo_id] = node.neo_id
      tx[:key] = key
      tx[:old_value] = old_value
      tx[:new_value] = new_value
      tx_nodes << tx
    end

    def on_relationship_created(relationship)
      # check so that it was no this method that caused this event
      return if tx_nodes.relationship_type.to_sym == relationship.relationship_type.to_sym
      tx = TxRelationshipCreatedNode.new
      uuid = Neo4j.create_uuid
      tx[:uuid] = uuid
      tx[:relationship_created] = true
      tx[:tracked_neo_id] = relationship.neo_id
      tx[:start_node_uuid] = relationship.start_node[:uuid]
      tx[:end_node_uuid] = relationship.end_node[:uuid]
      tx[:relationship_type] = relationship.relationship_type.to_s
      relationship[:uuid] = uuid
      tx_nodes << tx
    end


    def on_relationship_deleted(relationship)
      # check so that it was no this method that caused this event
      return if tx_nodes.relationship_type.to_sym == relationship.relationship_type.to_sym
      tx = TxNode.new
      uuid = Neo4j.create_uuid
      tx[:uuid] = uuid
      tx[:relationship_deleted] = true
      tx[:tracked_neo_id] = relationship.neo_id
      tx[:relationship_type] = relationship.relationship_type.to_s
      tx[:start_node_uuid] = relationship.start_node[:uuid]
      tx[:end_node_uuid] = relationship.end_node[:uuid]
      tx_nodes << tx
    end


    # Return a list of TxNodes that belongs to the same transaction
    # Will always include the specified from_tx_node
    # It will follow the linked list of tx nodes until it founds a new transaction.
    def tx_nodes_belonging_to_same_tx(from_tx_node)
      nodes_in_same_tx = []
      nodes_in_same_tx << from_tx_node # always include the first one

      # include all other nodes until we find a new transaction marker
      curr_node = from_tx_node

      while (true) do
        curr_node = curr_node.list(:tx_nodes).next
        break if curr_node.nil?
        break if curr_node[:tx_finished]
        nodes_in_same_tx << curr_node
      end
      nodes_in_same_tx
    end

    def create_node(tx_node)
      classname = tx_node[:tracked_classname]
      node = if classname.nil?
        Neo4j::Node.new
      else
        clazz = classname.split("::").inject(Kernel) do |container, name|
          container.const_get(name.to_s)
        end
        clazz.new
      end

      uuid = tx_node[:uuid]
      tx_node = find_tx(node.neo_id, :tracked_neo_id)
      #tx_node = find_tx_node(uuid)
      tx_node[:uuid] = uuid
      tx_node[:tracked_neo_id] = node.neo_id
      node[:uuid] = uuid
    end

    def delete_node(tx_node)
      uuid = tx_node[:uuid]
      node = load_node_with_uuid(uuid)
      node.del
    end

    def undo_property_changed(tx_node)
      uuid = tx_node[:uuid]
      node = load_node_with_uuid(uuid)
      key = tx_node[:key]
      old_value = tx_node[:old_value]
      node[key] = old_value
    end

    def redo_property_changed(tx_node)
      uuid = tx_node[:uuid]
      node = load_node_with_uuid(uuid)
      key = tx_node[:key]
      new_value = tx_node[:new_value]
      node[key] = new_value
    end

    def create_relationship(tx_node)
      # recreate deleted relationship
      type = tx_node[:relationship_type]
      start_node_uuid = tx_node[:start_node_uuid]
      end_node_uuid = tx_node[:end_node_uuid]
      start_node = load_node_with_uuid(start_node_uuid)
      end_node = load_node_with_uuid(end_node_uuid)
      start_node.rels.outgoing(type) << end_node
    end

    def delete_relationship(tx_node)
      relationship = load_relationship_with_uuid(tx_node[:uuid])
      relationship.del
    end


    def redo_tx(from_tx_node)
      nodes_to_redo = tx_nodes_belonging_to_same_tx(from_tx_node)
      nodes_to_redo.reverse_each do |curr_node|
        if (curr_node[:created])
          create_node(curr_node)
        elsif (curr_node[:deleted])
          delete_node(curr_node)
        elsif (curr_node[:property_changed])
          redo_property_changed(curr_node)
        elsif (curr_node[:relationship_created])
          create_relationship(curr_node)
        elsif (curr_node[:relationship_deleted])
          delete_relationship(curr_node)
        else
          raise "unknow tx #{curr_node.props.inspect}"
        end
      end
    end

    def undo_tx(from_tx_node = tx_nodes.first)
      return if from_tx_node.nil?

      nodes_to_undo = tx_nodes_belonging_to_same_tx(from_tx_node)

      nodes_to_undo.each do |curr_node|
        if (curr_node[:created])
          delete_node(curr_node)
        elsif (curr_node[:deleted])
          create_node(curr_node)
        elsif (curr_node[:property_changed])
          undo_property_changed(curr_node)
        elsif (curr_node[:relationship_created])
          delete_relationship(curr_node)
        elsif (curr_node[:relationship_deleted])
          create_relationship(curr_node)
        else
          raise "unknow tx #{curr_node.props.inspect}"
        end
      end
    end


    # Load a neo4j node given a cluster wide UUID (instead of id)
    # :api: public
    def load_node_with_uuid(uuid)
      txnode = find_tx_node(uuid)
      return if txnode.nil?
      # does this node exist ?
      id = txnode[:tracked_neo_id]
      Neo4j.load_node(id)
    end


    # Load a neo4j relatinship given a cluster wide UUID (instead of id)
    # :api: public
    def load_relationship_with_uuid(uuid)
      txnode = find_tx_relationship(uuid)
      return if txnode.nil?
      # does this node exist ?
      id = txnode[:tracked_neo_id]
      Neo4j.load_rel(id)
    end


    # :api: private
    def find_tx_node(uuid) # :nodoc:
      # since lucene only updates the index after the transaction commits we
      # first look in the current transaction
      found = find_tx(uuid)
      # if not found that find it with lucene
      found ||= TxNodeCreated.find(:uuid => uuid).first
      found
    end


    # :api: private
    def find_tx_relationship(uuid) # :nodoc:
      TxRelationshipCreatedNode.find(:uuid => uuid).first
    end


    # Find a TxNodeCreate node in the latest transaction with the given uuid
    def find_tx(value, key = :uuid) # :nodoc:
      tx_nodes.find {|node| node[:_classname] == TxNodeCreated.to_s && node[key] == value}
    end

    # Create a new a neo4j node given a cluster wide UUID (instead of id)
    # :nodoc:
    # :api: private
    def create_node_with_uuid(uuid)
      txnode = find_tx_node(uuid)
      return if txnode.nil?
      # does this node exist ?
      id = txnode[:tracked_neo_id]
      Neo4j.load_node(id)
    end

    #
    # Class methods ------------------------------------------------------
    #

    def self.on_neo_started(neo_instance)
      Neo4j::Transaction.run do
        # has the tx_node_list already been created ?
        unless neo_instance.ref_node.rel?(:tx_node_list)
          # it does not exist - create it
          neo_instance.ref_node.rels.outgoing(:tx_node_list) << TxNodeList.new
        end
        # cache this so we do not have to look it up always
        @tx_node_list = neo_instance.ref_node.rels.outgoing(:tx_node_list).nodes.first
        Neo4j.event_handler.add(@tx_node_list)
      end
    end

    def self.on_neo_stopped(neo_instance)
      # unregister the instance
      Neo4j.event_handler.remove(@tx_node_list)
      @tx_node_list = nil
    end


    def self.instance
      Neo4j.start unless @tx_node_list
      @tx_node_list
    end
  end


  # Keeps the uuid of created relationship in a lucene index
  class TxRelationshipCreatedNode
    include Neo4j::NodeMixin

    belongs_to_list(:tx_nodes).relationship(TxNodeRelationship)

    property :uuid
    index :uuid

    def to_s
      "TxRelationshipCreatedNode: " + props.inspect
    end
  end


  # Keeps the uuid of created nodes in a lucene index
  class TxNodeCreated
    include Neo4j::NodeMixin

    belongs_to_list(:tx_nodes).relationship(TxNodeRelationship)

    property :uuid
    index :uuid

    def to_s
      "TxNodeCreated: " + props.inspect
    end
  end


  # Represent an events like property change
  # Does not represend events for relationship and node creations
  class TxNode
    include Neo4j::NodeMixin

    belongs_to_list(:tx_nodes).relationship(TxNodeRelationship)

    def to_s
      "TxNode: " + props.inspect
    end
  end


  #-------------------------------------------------
  # Neo4j Module Methods
  #
  #-------------------------------------------------


  # Loads the tx tracker extension
  def self.load_tx_tracker
    Neo4j.event_handler.add_filter(TxNode)
    Neo4j.event_handler.add_filter(TxNodeCreated)
    Neo4j.event_handler.add_filter(TxRelationshipCreatedNode)

    Neo4j.event_handler.add(TxNodeList)
    Neo4j.event_handler.add(TxNodeRelationship)
    # if neo is already run we have to let txnodelist have a chance to add it self
    # TxNodeList.on_neo_started(Neo4j.instance) if Neo4j.running?
    Neo4j::Transaction.run { TxNodeList.on_neo_started(Neo4j.instance) } if Neo4j.running?
  end

  def self.unload_tx_tracker
    Neo4j.event_handler.remove_filter(TxNode)
    Neo4j.event_handler.remove_filter(TxNodeCreated)
    Neo4j.event_handler.remove_filter(TxRelationshipCreatedNode)

    Neo4j.event_handler.remove(TxNodeList)
    Neo4j.event_handler.remove(TxNodeRelationship)
  end

  #  Undo the last transaction
  #
  # :api: public
  def self.undo_tx
    TxNodeList.instance.undo_tx
  end


  #  Loads a node with the given uuid
  #  Returns nil if not found other wise the Node.
  # :api: public
  def self.load_node_with_uuid(uuid)
    TxNodeList.instance.load_node_with_uuid(uuid)
  end


  #  Loads a relationship with the given uuid
  #  Returns nil if not found other wise the Node.
  # :api: public
  def self.load_relationship_with_uuid(uuid)
    TxNodeList.instance.load_relationship_with_uuid(uuid)
  end

# Generates a new unique uuid
  def self.create_uuid
    rand(100000000) # TODO a very bad UUID generator ...
  end

  Neo4j.load_tx_tracker


end