module Neo4j

  # This nodes listen for all events like node nodes created/deleted or
  # if a property/relationship has changed. When a event is triggered it
  #
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
      tx = TxNode.new
      uuid = "UUID:#{node.neo_node_id}"
      node[:uuid] = uuid
      tx[:uuid] = uuid
      tx[:created] = true
      self.tx_nodes << tx
    end

    def self.on_neo_started(neo_instance)
      return if neo_instance.ref_node.relationship?(:tx_node_list)
      @tx_node_list = TxNodeList.new # cache this so we do not have to look it up always
      neo_instance.ref_node.add_relationship(@tx_node_list, :tx_node_list)
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
  end

  # Add this so it can add it self as listener
  Neo4j.event_handler.add_filter(TxNode)
  Neo4j.event_handler.add(TxNodeList)

end