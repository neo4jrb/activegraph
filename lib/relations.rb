module Neo
  class Relations
    include Enumerable
    
    def initialize(node, type)
      @node = node
      @type = RelationshipType.instance(type)      
    end
    
    def each
      traverser = @node.internal_node.traverse(org.neo4j.api.core.Traverser::Order::BREADTH_FIRST, 
        StopEvaluator::DEPTH_ONE,
        ReturnableEvaluator::ALL_BUT_START_NODE,
        @type,
        Direction::OUTGOING)
      
      iter = traverser.iterator
      while (iter.hasNext) do
        yield Neo::load_node(iter.next)
      end
    end
      
    
    def <<(other)
      @node.internal_node.createRelationshipTo(other.internal_node, @type)
      self
    end
  end
end