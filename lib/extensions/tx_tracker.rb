module Neo4j

  # This nodes listen for all events like node nodes created/deleted or
  # if a property/relationship has changed. When a event is triggered it
  #
  class TxNodeList
    include Neo4j::NodeMixin

    has_list :tx_nodes

    def initialize(*args)
      super(args)

      # its is configurable if we should track nodes or not
      if (Config[:track_tx])
        #Neo4j.instance.event_handler.add_listener(self)
      end
    end

    def on_node_created(node)
      tx = TxNodeCreated.new
      uuid = rand
      node[:uuid] = uuid   # TODO should use a better UUID
      tx[:tracked_node_id] = node.neo_node_id
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
      tx[:tracked_node_id] = node.neo_node_id
      tx[:key] = key
      tx[:old_value] = old_value
      tx[:new_value] = new_value
      tx_nodes << tx
    end


    def undo_tx
      tx_node = tx_nodes.first
      tracked_node_id = tx_node[:tracked_node_id]

      if (tx_node[:created])
        node = Neo4j.load(tracked_node_id)
        node.delete
      elsif (tx_node[:deleted])
        classname =  tx_node[:tracked_classname]
        clazz = classname.split("::").inject(Kernel) do |container, name|
          container.const_get(name.to_s)
        end
        node = clazz.new
      elsif (tx_node[:property_changed])
        node = Neo4j.load(tracked_node_id)
        key = tx_node[:key]
        old_value = tx_node[:old_value]
        node[key] = old_value
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

    property :uuid

    def to_s
      "TxNode: " + props.inspect
    end
  end

  class TxNodeCreated
    include Neo4j::NodeMixin

    property :uuid
    property :tracked_node_id

    index :uuid

    def to_s
      "TxNodeCreated: " + props.inspect
    end
  end

# Add this so it can add it self as listener
  Neo4j.event_handler.add_filter(TxNode)
  Neo4j.event_handler.add_filter(TxNodeCreated)
  Neo4j.event_handler.add(TxNodeList)

# if neo is already run we have to let txnodelist have a chance to add it self
  # TxNodeList.on_neo_started(Neo4j.instance) if Neo4j.running?

#  Undo the last transaction
#
# :api: public
  def self.undo_tx
    TxNodeList.instance.undo_tx
  end

  def self.load_uuid(uuid)
    txnode = TxNodeCreated.find(:uuid => uuid)
    # does this node exist ?
    id = txnode[:tracked_node_id]
    node = Neo4j.load(id)

    # if it does not exist we need to create a new node
  end
end