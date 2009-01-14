module Neo4j
  module Relations

    class IllegalTraversalArguments < StandardError; end
    
    # Enables traversing nodes
    # TODO duplicated code, see RelationTraverser,  Inheritance ?
    class NodeTraverser
      include Enumerable

      attr_reader :internal_node

      def initialize(internal_node)
        @internal_node = internal_node
        @stop_evaluator = DepthStopEvaluator.new(1)
        # what types of relationships and which directions should be traversed
        @types_and_dirs = []
      end

      def outgoing(*types)
        types.each do |type|
          @types_and_dirs << RelationshipType.instance(type)
          @types_and_dirs << org.neo4j.api.core.Direction::OUTGOING
        end
        self
      end

      def incoming(*types)
        types.each do |type|
          @types_and_dirs << RelationshipType.instance(type)
          @types_and_dirs << org.neo4j.api.core.Direction::INCOMING
        end
        self
      end

      def both(*types)
        types.each do |type|
          @types_and_dirs << RelationshipType.instance(type)
          @types_and_dirs << org.neo4j.api.core.Direction::BOTH
        end
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
            yield Neo4j.load(n.get_id)
          end
        end
      end

      def iterator
        # check that we know which type of relationship should be traversed
        if @types_and_dirs.empty?
          raise IllegalTraversalArguments.new "Unknown type of relationship. Needs to know which type(s) of relationship in order to traverse. Please use the outgoing, incoming or both method."
        end
        
        # create the traverser iterator
        #        @internal_node.traverse(org.neo4j.api.core.Traverser::Order::BREADTH_FIRST,
        #          @stop_evaluator,
        #          org.neo4j.api.core.ReturnableEvaluator::ALL_BUT_START_NODE,
        #          RelationshipType.instance(@type),
        #          @direction).iterator
        @internal_node.traverse(org.neo4j.api.core.Traverser::Order::BREADTH_FIRST,
          @stop_evaluator,
          org.neo4j.api.core.ReturnableEvaluator::ALL_BUT_START_NODE,
          @types_and_dirs.to_java(:object)).iterator
      end

      def to_s
        "NodeTraverser [direction=#{@direction}, type=#{@type}]"
      end

    end

  
  end
end
