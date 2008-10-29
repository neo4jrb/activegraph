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
    
    def outgoing(type = nil)
      @type = type
      @direction = Direction::OUTGOING
      self
    end

    def incoming(type = nil)
      @type = type      
      @direction = Direction::INCOMING
      self
    end

    def  both(type = nil)
      @type = type      
      @direction = Direction::BOTH
      self
    end
    
    def empty?
      !iterator.hasNext
    end
    
    # 
    # Returns the relationship object to the other node.
    #
    def [](other_node)
      find {|r| r.end_node.neo_node_id == other_node.neo_node_id}
    end
    
    
    
    def each
      Neo4j::Transaction.run do
        iter = iterator
        while (iter.hasNext) do
          n = iter.next
          yield Neo4j::Neo.instance.load_relationship(n)
        end
      end
    end

    
    def nodes
      RelationsNodes.new(self)
    end
    
    def iterator
      return @internal_node.getRelationships(@direction).iterator if @type.nil?
      return @internal_node.getRelationships(RelationshipType.instance(@type), @direction).iterator unless @type.nil?
    end
  end


  #
  # Used from Relations when traversing nodes instead of relationships.
  #
  class RelationsNodes
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
  # Enables traversal of nodes of a specific type that one node has.
  # Used for traversing relationship of a specific type.
  # Neo4j::NodeMixin can declare
  #
  class HasNRelations
    include Enumerable
    extend Neo4j::TransactionalMixin
    
    # TODO other_node_class not used ?
    def initialize(node, type, &filter)
      @node = node
      @type = RelationshipType.instance(type)      
      @filter = filter
      @depth = 1
      @info = node.class.relations_info[type.to_sym]

      if @info[:outgoing]
        @direction = Direction::OUTGOING
        @type = RelationshipType.instance(type)
      else
        @direction = Direction::INCOMING
        other_class_type = @info[:type].to_s
        @type = RelationshipType.instance(other_class_type)      
      end
    end
    
       
    def each
      stop = DepthStopEvaluator.new(@depth)
      traverser = @node.internal_node.traverse(org.neo4j.api.core.Traverser::Order::BREADTH_FIRST, 
        stop, #StopEvaluator::DEPTH_ONE,
        ReturnableEvaluator::ALL_BUT_START_NODE,
        @type,
        @direction)
      Neo4j::Transaction.run do
        iter = traverser.iterator
        while (iter.hasNext) do
          node = Neo4j::Neo.instance.load_node(iter.next)
          if !@filter.nil?
            res =  node.instance_eval(&@filter)
            next unless res
          end
          yield node
        end
      end
    end
      
    #
    # Creates a relationship instance between this and the other node.
    # If a class for the relationship has not been specified it will be of type DynamicRelation.
    # To set a relationship type see #Neo4j::relations
    #
    def new(other)
      from, to = @node, other
      from,to = to,from unless @info[:outgoing]
      
      r = Neo4j::Transaction.run {
        from.internal_node.createRelationshipTo(to.internal_node, @type)
      }
      from.class.relations_info[@type.name.to_sym][:relation].new(r)
    end
    
    
    #
    # Creates a relationship between this and the other node.
    # Returns self so that we can add several nodes like this:
    # 
    #   n1 = Node.new # Node has declared having a friend type of relationship
    #   n2 = Node.new
    #   n3 = NodeMixin.new
    #   
    #   n1 << n2 << n3
    #
    # This is the same as:
    #  
    #   n1.friends.new(n2)
    #   n1.friends.new(n3)
    #
    def <<(other)
      from, to = @node, other
      from,to = to,from unless @info[:outgoing]
      
      r = from.internal_node.createRelationshipTo(to.internal_node, @type)
      from.class.new_relation(@type.name,r)
      from.class.fire_event(RelationshipAddedEvent.new(from, to, @type.name, r.getId()))
      other.class.fire_event(RelationshipAddedEvent.new(to, from, @type.name, r.getId()))
      self
    end


    #
    # Private class
    #
    class DepthStopEvaluator
      include StopEvaluator

      def initialize(depth)
        @depth = depth
      end

      def isStopNode(pos)
        pos.depth >= @depth
      end
    end

    transactional :<<
    end
  
  #
  # This is a private class holding the type of a relationship
  # 
  class RelationshipType
    include org.neo4j.api.core.RelationshipType

    @@names = {}
    
    def RelationshipType.instance(name)
      return @@names[name] if @@names.include?(name)
      @@names[name] = RelationshipType.new(name)
    end

    def to_s
      self.class.to_s + " name='#{@name}'"
    end

    def name
      @name
    end
    
    private
    
    def initialize(name)
      @name = name.to_s
      raise ArgumentError.new("Expect type of relation to be a name of at least one character") if @name.empty?
    end
    
  end
  
end