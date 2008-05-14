include Java




module Neo
  
  require 'neo-1.0-b6.jar'
  require 'jta-spec1_0_1.jar'

  
  EmbeddedNeo = org.neo4j.api.core.EmbeddedNeo
  Transaction = org.neo4j.api.core.Transaction
  StopEvaluator = org.neo4j.api.core.StopEvaluator
  Traverser = org.neo4j.api.core.Traverser
  ReturnableEvaluator = org.neo4j.api.core.ReturnableEvaluator
  Direction = org.neo4j.api.core.Direction
  
  def start
    puts "start neo"
    @@neo = EmbeddedNeo.new("var/neo")  
  end

  def stop
    @@neo.shutdown  
  end
  
  def transaction      
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
  
  def create_node
    @@neo.createNode
  end

  
  class Node
    
    attr_reader :internal_node 
    
    def initialize
      if block_given? # check if we should run in a transaction
        transaction { @internal_node = Neo.create_node; yield self } 
      else
        @internal_node = Neo.create_node  
      end
    end
  
    def self.properties(*props)
      props.each do |prop|
        puts "Define #{prop}"
        define_method(prop) do 
          puts "Get #{prop}"       
          @internal_node.get_property(prop.to_s)
        end

        name = (prop.to_s() +"=")
        define_method(name) do |value|
          puts "Set #{prop} to #{value}"               
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
      puts "Traverser #{traverser.inspect}"

      iter = traverser.iterator
      while (iter.hasNext) do
        yield iter.next
      end
    end
    
    
    def <<(other)
      puts "added #{other}"
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


############################################################
# Example of usage
include Neo

start

class Person < Node
  properties :name, :age 
#  relations :friend, :child
end

class Employee < Person
  properties :salary 
  
  def to_s
    "Employee #{@name}"
  end
end

n1 = Employee.new do |node| # this code body is run in a transaction
  node.name = "kalle"
  node.salary = 10
end 

n2 = Employee.new do |node| # this code body is run in a transaction
  node.name = "sune"
  node.salary = 20
  node.friends << n1
end 

puts "Name #{n1.name}, salary: #{n1.salary}"

n2.friends.each {|n| puts "Node #{n.inspect}"}

#n1.friends << "hoho"

#r1 = RelationshipType.instance 'kalle'
#r2 = RelationshipType.instance 'kalle'
#puts "NAME #{r1.inspect} = #{r2.inspect}"

#exit

stop

