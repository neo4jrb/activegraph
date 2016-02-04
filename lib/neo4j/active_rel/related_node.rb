module Neo4j::ActiveRel
  # A container for ActiveRel's :inbound and :outbound methods. It provides lazy loading of nodes.
  # It's important (or maybe not really IMPORTANT, but at least worth mentioning) that calling method_missing
  # will result in a query to load the node if the node is not already loaded.
  class RelatedNode
    class UnsetRelatedNodeError < Neo4j::Error; end

    # ActiveRel's related nodes can be initialized with nothing, an integer, or a fully wrapped node.
    #
    # Initialization with nothing happens when a new, non-persisted ActiveRel object is first initialized.
    #
    # Initialization with an integer happens when a relationship is loaded from the database. It loads using the ID
    # because that is provided by the Cypher response and does not require an extra query.
    def initialize(node = nil)
      @node = valid_node_param?(node) ? node : (fail Neo4j::InvalidParameterError, 'RelatedNode must be initialized with either a node ID or node')
    end

    # Loads the node if needed, then conducts comparison.
    def ==(other)
      loaded if @node.is_a?(Integer)
      @node == other
    end

    # Returns the neo_id of a given node without loading.
    def neo_id
      loaded? ? @node.neo_id : @node
    end

    # Loads a node from the database or returns the node if already laoded
    def loaded
      fail UnsetRelatedNodeError, 'Node not set, cannot load' if @node.nil?
      @node = @node.respond_to?(:neo_id) ? @node : Neo4j::Node.load(@node)
    end

    # @param [String, Symbol, Array] clazz An alternate label to use in the event the node is not present or loaded
    def cypher_representation(clazz)
      case
      when !set?
        "(#{formatted_label_list(clazz)})"
      when set? && !loaded?
        "(Node with neo_id #{@node})"
      else
        node_class = self.class
        id_name = node_class.id_property_name
        labels = ':' + node_class.mapped_label_names.join(':')

        "(#{labels} {#{id_name}: #{@node.id.inspect}})"
      end
    end

    # @return [Boolean] indicates whether a node has or has not been fully loaded from the database
    def loaded?
      @node.respond_to?(:neo_id)
    end

    def set?
      !@node.nil?
    end

    def method_missing(*args, &block)
      loaded.send(*args, &block)
    end

    def respond_to_missing?(method_name, include_private = false)
      loaded if @node.is_a?(Numeric)
      @node.respond_to?(method_name) ? true : super
    end

    def class
      loaded.send(:class)
    end

    private

    def formatted_label_list(list)
      list.is_a?(Array) ? list.join(' || ') : list
    end

    def valid_node_param?(node)
      node.nil? || node.is_a?(Integer) || node.respond_to?(:neo_id)
    end
  end
end
