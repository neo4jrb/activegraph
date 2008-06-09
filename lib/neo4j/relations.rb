
module Neo4j
  
  
  #
  # Enables finding relations for one node
  #
  class Relations
    include Enumerable
    
    attr_reader :internal_node 
    
    def initialize(internal_node)
      @internal_node = internal_node
      @direction = Direction::BOTH
    end
    
    def outgoing
      @direction = Direction::OUTGOING
      self
    end

    def incoming
      @direction = Direction::INCOMING
      self
    end

    def  both
      @direction = Direction::BOTH
      self
    end
    
    def each
      iter = @internal_node.getRelationships(@direction)
      while (iter.hasNext) do
        yield Relation.new(iter.next)
      end
    end

    
    def nodes
      RelationNode.new(self)
    end
  end


  class RelationNode
    include Enumerable
    
    def initialize(relations)
      @relations = relations
    end
    
    def each
      @relations.each do |relation|
        yield relation.other_node(@relations.internal_node)
      end
    end
  end
  
  #
  # Wrapper class for a java org.neo4j.api.core.Relationship class
  #
  class Relation
  
    def initialize(r)
      @internal_r = r
    end
  
    def end_node
      BaseNode.new(@internal_r.getEndNode)
    end
  
    def start_node
      BaseNode.new(@internal_r.getStartNode)
    end
  
    def other_node(node)
      BaseNode.new(@internal_r.getOtherNode(node))
    end
    
    def delete
      @internal_r.delete
    end
  end

  #
  # Enables traversal of nodes of a specific type that one node has.
  #
  class NodesWithRelationType
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
        yield Neo4j::Neo.instance.load_node(iter.next)
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