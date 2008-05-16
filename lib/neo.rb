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
    
    # add a super node having subnodes to all metaclasses
    # a metaclass is a node that is created for each time someone inherits from the Node class
    transaction do
      @@metaclasses_node = RubyMetaClasses.new  # TODO (@@neo.getReferenceNode)
    end
    
  end

  def self.metaclasses_node
    @@metaclasses_node
  end
  
  def self.find_metaclass(classname) 
    metaclasses_node.nodes.find{|node| node.classname == classname}    
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
    
    def initialize(*args)
      if args.length == 1 and args[0].kind_of?(org.neo4j.api.core.Node)
        @internal_node = args[0]
        # TODO check if a transaction is needed
        Neo.transaction {self.metaclass = self.class.to_s}
      elsif block_given? # check if we should run in a transaction
        Neo.transaction { init_internal; yield self }
      else
        init_internal
      end
    end
    
    def init_internal
      @internal_node = Neo::create_node  
      self.metaclass = self.class.to_s
      # TODO set metaclass node to point to self
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
        err = "method '#{name}' has wrong number of arguments (#{args.size} for #{expected_args})"
        raise ArgumentError.new(err)
      end

      if setter
          @internal_node.set_property(name, args[0])
      else
          return @internal_node.get_property(name)
      end      
    end
    
    def self.inherited(c)
      if c == Neo::RubyMetaClass or c == Neo::RubyMetaClasses
        return
      end
      # TODO check: should only be created once  ?      
      RubyMetaClass.new do |n|
       n.classname = c.to_s
       Neo::metaclasses_node.nodes << n
      end
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
    
    def self.add_relation_type(type)
        define_method(type) do 
          Relations.new(self,type.to_s)
        end
    end
    
    
    def self.relations(*relations)
      relations.each {|type| add_relation_type(type)}
    end

    properties :metaclass
  end

  
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
        inode = iter.next
        classname = inode.get_property('metaclass')
        
        # get the class that might exist in a module
        clazz = classname.split("::").inject(Kernel) do |container, name|
          container.const_get(name.to_s)
        end
        yield clazz.new(inode)
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
  
  
  class RubyMetaClass < Node
    properties :classname
    relations :instances
  end

  class RubyMetaClasses < Node
    relations :nodes
  end
  
end


