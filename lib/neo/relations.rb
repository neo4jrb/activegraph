
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
        yield Neo::neo_service.load_node(iter.next)
      end
    end
      
    
    def <<(other)
      @node.internal_node.createRelationshipTo(other.internal_node, @type)
      self
    end
  end
  
  #
  # This is a private class holding the type of a relationship
  # 
  class RelationshipType
    include org.neo4j.api.core.RelationshipType
    attr_accessor :name 

    @@names = {}
    
    def RelationshipType.instance(name)
      return @@names[name] if @@names.include?(name)
      @@names[name] = RelationshipType.new(name)
    end

    def to_s
      self.class.to_s + " name='#{@name}'"
    end

    private
    
    def initialize(name)
      @name = name.to_s
    end
    
  end
end