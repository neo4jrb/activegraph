include Java


module Neo
  
  require 'neo-1.0-b6.jar'
  require 'jta-spec1_0_1.jar'
  require 'index-util-0.4-20080512.110337-6.jar'
  require 'lucene-core-2.3.2.jar'

  
  EmbeddedNeo = org.neo4j.api.core.EmbeddedNeo
  Transaction = org.neo4j.api.core.Transaction
  StopEvaluator = org.neo4j.api.core.StopEvaluator
  Traverser = org.neo4j.api.core.Traverser
  ReturnableEvaluator = org.neo4j.api.core.ReturnableEvaluator
  Direction = org.neo4j.api.core.Direction
  IndexService = org.neo4j.util.index.IndexService
  
  def self.start
    puts "start neo"
    @@neo = EmbeddedNeo.new("var/neo")  
    
    transaction do
      @@metaclasses =Node.new
    end
    
  end

  def self.stop
    puts "stop neo"
    @@neo.shutdown  
  end
  
  def self.transaction      
    tx = Transaction.begin  
    begin  
      yield  
      tx.success  
    rescue Exception => e  
      raise e  
    ensure  
      tx.finish  
    end      
  end  
  
  def self.create_node
    @@neo.createNode
  end

  
  class Node
    attr_reader :internal_node 
    
    def initialize
      if block_given? # check if we should run in a transaction
        Neo.transaction { @internal_node = Neo::create_node; yield self }
      else
        @internal_node = Neo::create_node  
      end
      
      
      # TODO
      # Maybe we should create a meta node that knows what type this node is of, (if that meta node does not already exist )
      # A relationship is created between this new node and the meta node.
      # When do serialization back to ruby object from Neo we read this relationship and create the correct class
    end

    def method_missing(methodname, *args)
      name = methodname.to_s
      setter = /=$/ === name
      expected_args = 0
      if setter
        name = name[0...-1]
        expected_args = 1
      end
      unless args.size == expected_args
        err = "wrong number of arguments (#{args.size} for #{expected_args})"
        raise ArgumentError.new(err)
      end

      if setter
          @internal_node.set_property(name, args[0])
      else
          return @internal_node.get_property(name)
      end      
    end
    
    def self.inherited(c)
      # puts "Class #{c} < #{self}"
    end
    
    def self.properties(*props)
      props.each do |prop|
        define_method(prop) do 
          @internal_node.get_property(prop.to_s)
        end

        name = (prop.to_s() +"=")
        define_method(name) do |value|
          @internal_node.set_property(prop.to_s, value)
        end
      end
    end
    
    def self.relations(*relations)
      relations.each do |r|
        
        #        define_method(r) do 
      end
    end

    def friends
      Relations.new(self,RelationshipType.instance(:friend))
    end
    
  end

  
  class Relations
    include Enumerable
    
    def initialize(node, type)
      @node = node
      @type = type
    end
    
    def each
      traverser = @node.internal_node.traverse(org.neo4j.api.core.Traverser::Order::BREADTH_FIRST, 
        StopEvaluator::DEPTH_ONE,
        ReturnableEvaluator::ALL_BUT_START_NODE,
        RelationshipType.instance(:friend),
        Direction::OUTGOING)
      # puts "Traverser #{traverser.inspect}"

      iter = traverser.iterator
      while (iter.hasNext) do
        yield iter.next
      end
    end
    
    
    def <<(other)
      @node.internal_node.createRelationshipTo(other.internal_node, @type)
      self
    end
  end
  
  
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


