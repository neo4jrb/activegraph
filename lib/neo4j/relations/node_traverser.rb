module Neo4j
  module Relations

    # Enables traversing nodes
    #
    class NodeTraverser
      include Enumerable

      attr_reader :internal_node

      def initialize(internal_node)
        @internal_node = internal_node
        @direction = org.neo4j.api.core.Direction::BOTH
        @stop_evaluator = DepthStopEvaluator.new(1)
      end

      def outgoing(type = nil)
        @type = type
        @direction = org.neo4j.api.core.Direction::OUTGOING
        self
      end

      def incoming(type = nil)
        @type = type
        @direction = org.neo4j.api.core.Direction::INCOMING
        self
      end

      def both(type = nil)
        @type = type
        @direction = org.neo4j.api.core.Direction::BOTH
        self
      end

      def empty?
        Neo4j::Transaction.run {!iterator.hasNext}
      end

      def each
        Neo4j::Transaction.run do
          iter = iterator
          while (iter.hasNext) do
            n = iter.next
            yield Neo4j.load(n)
          end
        end
      end

      def iterator
        # check that we know which type of relationship should be traversed
        raise "Unknown type of relationship. Need to know which type(s) of relationship in order to traverse" if @type.nil?

        # create the traverser iterator
        @internal_node.traverse(org.neo4j.api.core.Traverser::Order::BREADTH_FIRST,
          @stop_evaluator,
          org.neo4j.api.core.ReturnableEvaluator::ALL_BUT_START_NODE,
          RelationshipType.instance(@type),
          @direction).iterator
      end

      def to_s
        "NodeTraverser [direction=#{@direction}, type=#{@type}]"
      end

    end

  
  end
end
