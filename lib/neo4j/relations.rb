
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
        yield RelationWrapper.new(iter.next)
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
  class RelationWrapper
  
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

    def set_property(key,value)
      @internal_r.setProperty(key,value)
    end    
    
    def property?(key)
      @internal_r.hasProperty(key)
    end
    
    def get_property(key)
      @internal_r.getProperty(key)
    end
    #
    # A hook used to set and get undeclared properties
    #
    def method_missing(methodname, *args)
      # allows to set and get any neo property without declaring them first
      name = methodname.to_s
      setter = /=$/ === name
      expected_args = 0
      if setter
        name = name[0...-1]
        expected_args = 1
      end
      unless args.size == expected_args
        err = "method '#{name}' on '#{self.class.to_s}' has wrong number of arguments (#{args.size} for #{expected_args})"
        raise ArgumentError.new(err)
      end

      if setter
        set_property(name, args[0])
      else
        get_property(name)
      end
    end
    
  end

  #
  # Enables traversal of nodes of a specific type that one node has.
  #
  class NodesWithRelationType
    include Enumerable
    
    
    def initialize(node, type, other_node_class = nil)
      @node = node
      @type = RelationshipType.instance(type)      
      @other_node_class = other_node_class
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
      
    #
    # Creates a relationship between this and the other node.
    # Returns the relationship object that has property like a Node has.
    #
    #   n1 = Node.new # Node has declared having a friend type of relationship 
    #   n2 = Node.new
    #   
    #   relation = n1.friends.new(n2)
    #   relation.friend_since = 1992 # set a property on this relationship
    #
    def new(other)
      r = @node.internal_node.createRelationshipTo(other.internal_node, @type)
      RelationWrapper.new(r)
    end
    
    
    #
    # Creates a relationship between this and the other node.
    # Returns self so that we can add several nodes like this:
    # 
    #   n1 = Node.new # Node has declared having a friend type of relationship
    #   n2 = Node.new
    #   n3 = Node.new
    #   
    #   n1 << n2 << n3
    #
    # This is the same as:
    #  
    #   n1.friends.new(n2)
    #   n1.friends.new(n3)
    #
    def <<(other)
      # TODO, should we check if we should create a new transaction ?
      # TODO, should we update lucene index ?
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