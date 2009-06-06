module Neo4j

  # Handles events like a new node is created or deleted
  class EventHandler
    def initialize
      @listeners = []
    end

    def add_listener(listener)
      @listeners << listener
    end

    def remove_all_listeners
      @listeners = nil
    end
      
    def node_created(node)
      @listeners.each {|li| li.on_node_created(node)}
    end

    def node_deleted(node)
      @listeners.each {|li| li.on_node_deleted(node)}
    end
  end
end
