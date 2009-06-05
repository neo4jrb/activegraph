module Neo4j

  # Handles events like a new node is created or deleted
  class EventHandler
    # class methods
    class <<self
      def listeners
        @listeners ||= []
        @listeners
      end

      def remove_all_listeners
        @listeners = nil
      end
      
      def node_created(node)
        self.listeners.each {|li| li.on_node_created(node)}
      end

      def node_deleted(node)
        self.listeners.each {|li| li.on_node_deleted(node)}
      end
    end
  end
end