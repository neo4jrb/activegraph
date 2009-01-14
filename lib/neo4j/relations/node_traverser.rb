module Neo4j
  module Relations

    class IllegalTraversalArguments < StandardError; end
    
    # Enables traversing nodes
    # Contains state about one specific traversal to be performed.
    class NodeTraverser
      include Enumerable

      attr_reader :internal_node

      def initialize(internal_node)
        @internal_node = internal_node
        @stop_evaluator = DepthStopEvaluator.new(1)
        @types_and_dirs = [] # what types of relationships and which directions should be traversed
        @traverser_order = org.neo4j.api.core.Traverser::Order::BREADTH_FIRST
        @returnable_evaluator = org.neo4j.api.core.ReturnableEvaluator::ALL_BUT_START_NODE
      end

      # Sets the depth of the traversal.
      # Default is 1 if not specified.
      #
      # ==== Example
      #  morpheus.traverse.outgoing(:friends).depth(:all).each { ... }
      #  morpheus.traverse.outgoing(:friends).depth(3).each { ... }
      #
      # ==== Arguments
      # d<Fixnum,Symbol>:: the depth or :all if traversing to the end of the network.
      # ==== Return
      # self
      #
      # :api: public
      def depth(d)
        if d == :all
          @stop_evaluator = org.neo4j.api.core.StopEvaluator::END_OF_GRAPH
        else
          @stop_evaluator = DepthStopEvaluator.new(d)
        end
        self
      end

      def filter(&proc)
        @returnable_evaluator = ReturnableEvaluator.new proc
        self
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
        
        @internal_node.traverse(@traverser_order, @stop_evaluator,
          @returnable_evaluator, @types_and_dirs.to_java(:object)).iterator
      end

      def to_s
        "NodeTraverser [direction=#{@direction}, type=#{@type}]"
      end

    end

  
  end
end
