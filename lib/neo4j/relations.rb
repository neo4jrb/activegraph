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
      iter = iterator
      while (iter.hasNext) do
        n = iter.next
        yield Neo4j::Neo.instance.load_relationship(n)
      end
    end

    
    def nodes
      RelationNode.new(self)
    end
    
    def iterator
      return @internal_node.getRelationships(@direction).iterator if @type.nil?
      return @internal_node.getRelationships(RelationshipType.instance(@type), @direction).iterator unless @type.nil?
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
  
  module Relation
    extend Transactional
    
    def initialize(*args)
      if args.length == 1 and args[0].kind_of?(org.neo4j.api.core.Relationship)
        Transaction.run {init_with_rel(args[0])} unless Transaction.running?
        init_with_rel(args[0])                   if Transaction.running?
      else 
        raise ArgumentError.new("This code should not be executed - remove todo") 
        Transaction.run {init_without_rel} unless Transaction.running?        
        init_without_rel                   if Transaction.running?                
      end
      
      # must call super with no arguments so that chaining of initialize method will work
      super() 
    end
    
    #
    # Inits this node with the specified java neo node
    #
    def init_with_rel(node)
      @internal_r = node
      self.classname = self.class.to_s unless @internal_r.hasProperty("classname")
      $NEO_LOGGER.debug {"loading relation '#{self.class.to_s}' id #{@internal_r.getId()}"}
    end
    
    
    #
    # Inits when no neo java node exists. Must create a new neo java node first.
    #
    def init_without_rel
      @internal_r = Neo4j::Neo.instance.create_node
      self.classname = self.class.to_s
      self.class.fire_event RelationshipAddedEvent.new(self)  #from_node, to_node, relation_name, relation_id    
      $NEO_LOGGER.debug {"created new node '#{self.class.to_s}' node id: #{@internal_node.getId()}"}        
    end
    
    def end_node
      id = @internal_r.getEndNode.getId
      Neo.instance.find_node id
    end
  
    def start_node
      id = @internal_r.getStartNode.getId
      Neo.instance.find_node id
    end
  
    def other_node(node)
      id = @internal_r.getOtherNode(node).getId     
      Neo.instance.find_node id
    end
    
    #
    # Deletes the relationship between two nodes.
    # Will fire a RelationshipDeletedEvent on the start_node class.
    #
    def delete
      type = @internal_r.getType().name()
      start_node.class.fire_event(RelationshipDeletedEvent.new(start_node, end_node, type, @internal_r.getId))      
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
    
    def classname
      get_property('classname')
    end
    
    def classname=(value)
      set_property('classname', value)
    end
    
 
    def neo_relation_id
      @internal_r.getId()
    end
    
    transactional :property?, :set_property, :get_property, :delete
    
    #
    # Adds classmethods in the ClassMethods module
    #
    def self.included(c)
      c.extend ClassMethods
    end
    
    module ClassMethods
      def properties(*props)
        props.each do |prop|
          define_method(prop) do 
            get_property(prop.to_s)
          end

          name = (prop.to_s() +"=")
          define_method(name) do |value|
            set_property(prop.to_s, value)
          end
        end

      end
    end
  end  
  
  #
  # Wrapper class for a java org.neo4j.api.core.Relationship class
  #
  class DynamicRelation
    extend Neo4j::Transactional
    include Neo4j::Relation
  end

  #
  # Enables traversal of nodes of a specific type that one node has.
  #
  class NodesWithRelationType
    include Enumerable
    extend Neo4j::Transactional
    
    # TODO other_node_class not used ?
    def initialize(node, type, other_node_class = nil, &filter)
      @node = node
      @type = RelationshipType.instance(type)      
      @other_node_class = other_node_class
      @filter = filter
      @depth = 1
    end
    
       
    def each
      stop = DepthStopEvaluator.new(@depth)
      traverser = @node.internal_node.traverse(org.neo4j.api.core.Traverser::Order::BREADTH_FIRST, 
        stop, #StopEvaluator::DEPTH_ONE,
        ReturnableEvaluator::ALL_BUT_START_NODE,
        @type,
        Direction::OUTGOING)
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
      
    #
    # Creates a relationship instance between this and the other node.
    # If a class for the relationship has not been specified it will be of type DynamicRelation.
    # To set a relationship type see #Neo4j::relations
    #
    def new(other)
      r = Neo4j::Transaction.run {
       @node.internal_node.createRelationshipTo(other.internal_node, @type)
      }
      puts "@type.name = #{@type.name.to_sym}"
      puts "@node.class.relations_info[@type.name.to_sym]=#{@node.class.relations_info[@type.name.to_sym].info.inspect}"
      @node.class.relations_info[@type.name.to_sym][:relation].new(r)
      #@node.class.relation_types[@type.name.to_sym].new(r)
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
      r = @node.internal_node.createRelationshipTo(other.internal_node, @type)
      @node.class.new_relation(@type.name,r)
      @node.class.fire_event(RelationshipAddedEvent.new(@node, other, @type.name, r.getId()))
      other.class.fire_event(RelationshipAddedEvent.new(other, @node, @type.name, r.getId()))
      self
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
  
  class DepthStopEvaluator
    include StopEvaluator
    
    def initialize(depth)
      @depth = depth
    end
    
    def isStopNode(pos)
      pos.depth >= @depth
    end
  end
end