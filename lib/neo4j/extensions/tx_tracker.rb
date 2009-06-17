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
      uuid = create_uuid
      node[:uuid] = uuid   # TODO should use a better UUID
      tx[:tracked_neo_id] = node.neo_node_id
      tx[:created] = true
      tx[:uuid] = uuid
      tx_nodes << tx
    end

    def on_node_deleted(node)
      tx = TxNode.new
      tx[:uuid] = node[:uuid]
      tx[:deleted] = true
      tx[:tracked_classname] = node.class.to_s
      tx_nodes << tx
    end


    def on_tx_finished(tx)
      return if self.tx_nodes.empty? # nothing yet commited
      last_commited_node = self.tx_nodes.first
      last_commited_node[:tx_finished] = true
    end

    def on_property_changed(node, key, old_value, new_value)
      return if "uuid" == key.to_s  # do not track uuid
      tx = TxNode.new
      tx[:uuid] = node[:uuid]
      tx[:property_changed] = true
      tx[:tracked_neo_id] = node.neo_node_id
      tx[:key] = key
      tx[:old_value] = old_value
      tx[:new_value] = new_value
      tx_nodes << tx
    end

    def on_relationship_created(relationship)
      tx = TxNode.new
      uuid = create_uuid
      tx[:uuid] = uuid
      tx[:relationship_created] = true
      tx[:tracked_neo_id] = relationship.neo_relationship_id
      tx_nodes << tx
    end


    def on_relationship_deleted(relationship)
      tx = TxNode.new
      uuid = create_uuid
      tx[:uuid] = uuid
      tx[:relationship_deleted] = true
      tx[:tracked_neo_id] = relationship.neo_relationship_id
      tx[:relationship_type] = relationship.relationship_type.to_s
      tx[:start_node_id] = relationship.start_node.neo_node_id
      tx[:end_node_id] = relationship.end_node.neo_node_id

      tx_nodes << tx
    end

    def create_uuid
      rand(100000) # TODO a very bad UUID generator ...
    end


    def undo_tx
      first_node = tx_nodes.first
      return if first_node.nil?

      nodes_to_undo = []
      nodes_to_undo << first_node  # always include the first one

      # include all other nodes until we find a new transaction marker
      curr_node = first_node
      while (curr_node.relationship?(:tx_nodes, :outgoing)) do
        curr_node = curr_node.relationship(:tx_nodes, :outgoing).end_node
        break if curr_node[:tx_finished]
        nodes_to_undo << curr_node
      end

      nodes_to_undo.each do |curr_node|
        tracked_neo_id = curr_node[:tracked_neo_id]  # TODO - remove
        uuid = curr_node[:uuid]
        if (curr_node[:created])
          #node = Neo4j.load(tracked_neo_id)
          node = Neo4j.load_uuid(uuid)
          node.delete
        elsif (curr_node[:deleted])
          classname =  curr_node[:tracked_classname]
          clazz = classname.split("::").inject(Kernel) do |container, name|
            container.const_get(name.to_s)
          end
          node = clazz.new
        elsif (curr_node[:property_changed])
          node = Neo4j.load(tracked_neo_id)
          key = curr_node[:key]
          old_value = curr_node[:old_value]
          node[key] = old_value
        elsif (curr_node[:relationship_created])
          # delete created relationship
          relationship = Neo4j.load_relationship(tracked_neo_id)
          relationship.delete
        elsif (curr_node[:relationship_deleted])
          # recreate deleted relationship
          type = curr_node[:relationship_type]
          start_node_id = curr_node[:start_node_id]
          end_node_id = curr_node[:end_node_id]
          start_node = Neo4j.load(start_node_id)
          end_node = Neo4j.load(end_node_id)
          start_node.relationships.outgoing(type) << end_node
        end
      end
    end


    #
    # Class methods ------------------------------------------------------
    #

    def self.on_neo_started(neo_instance)
      return if neo_instance.ref_node.relationship?(:tx_node_list)
      @tx_node_list = TxNodeList.new # cache this so we do not have to look it up always
      neo_instance.ref_node.relationships.outgoing(:tx_node_list) << @tx_node_list
      Neo4j.event_handler.add(@tx_node_list)
    end

    def self.on_neo_stopped(neo_instance)
      # unregister the instance
      Neo4j.event_handler.remove(@tx_node_list)
      @tx_node_list = nil
    end


    def self.instance
      @tx_node_list
    end
  end


  class TxNode
    include Neo4j::NodeMixin

    belongs_to_list(:tx_nodes).relationship(TxNodeRelationship)

    property :uuid

    def to_s
      "TxNode: " + props.inspect
    end
  end

  class TxNodeCreated
    include Neo4j::NodeMixin

    belongs_to_list(:tx_nodes).relationship(TxNodeRelationship)

    property :uuid
    property :tracked_neo_id

    index :uuid

    def to_s
      "TxNodeCreated: " + props.inspect
    end
  end

# Add this so it can add it self as listener
  def self.load_tx_tracker
    Neo4j.event_handler.add_filter(TxNode)
    Neo4j.event_handler.add_filter(TxNodeCreated)
    Neo4j.event_handler.add(TxNodeList)
    Neo4j.event_handler.add(TxNodeRelationship)
    Neo4j::Transaction.run { TxNodeList.on_neo_started(Neo4j.instance) } if Neo4j.running?
  end

# if neo is already run we have to let txnodelist have a chance to add it self
  # TxNodeList.on_neo_started(Neo4j.instance) if Neo4j.running?

#  Undo the last transaction
#
# :api: public
  def self.undo_tx
    TxNodeList.instance.undo_tx
  end


  # Load a neo4j node given a cluster wide UUID (instead of neo_node_id)
  #
  # :api: public
  def self.load_uuid(uuid)
    txnode = TxNodeCreated.find(:uuid => uuid).first
    # does this node exist ?
    id = txnode[:tracked_neo_id]
    node = Neo4j.load(id)
  end

  load_tx_tracker

end