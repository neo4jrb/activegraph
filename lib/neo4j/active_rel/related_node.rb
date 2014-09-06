module Neo4j::ActiveRel
  # A container for ActiveRel's :inbound and :outbound methods. It provides lazy loading of nodes.
  class RelatedNode

    class InvalidParameterError < StandardError; end

    def initialize(node = nil)
      @node = valid_node_param?(node) ? node : (raise InvalidParameterError, 'RelatedNode must be initialized with either a node ID or node' )
    end

    def == (obj)
      loaded if @node.is_a?(Fixnum)
      @node == obj
    end

    def loaded
      @node = @node.respond_to?(:neo_id) ? @node : Neo4j::Node.load(@node)
    end

    def loaded?
      @node.respond_to?(:neo_id)
    end

    def method_missing(*args, &block)
      loaded.send(*args, &block)
    end

    def class
      loaded.send(:class)
    end

    private

    def valid_node_param?(node)
      node.nil? || node.is_a?(Integer) || node.respond_to?(:neo_id)
    end
  end
end