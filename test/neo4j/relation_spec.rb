require 'neo4j'
require 'neo4j/spec_helper'




describe "When NOT running in one transaction" do
  before(:all) do
    start
  end

  after(:all) do
    stop
  end  
  
  
  
  it "It should create a new transaction when updating a relationship" do
    pending "Refactoring needed, should be easier to declare methods as transactional"
    class FooNode 
      include Neo4j::Node
      
      relations :friends
    end
      
    f1 = FooNode.new
    f2 = FooNode.new
    f1.friends << f2
  end
end

# ------------------------------------------------------------------------------
# the following specs are run inside one Neo4j transaction
# 

describe "When running in one transaction" do
  before(:all) do
    start
    @transaction = Neo4j::Transaction.new 
    @transaction.start
  end

  after(:all) do
    @transaction.failure # do not want to store anything
    @transaction.finish
    stop
  end  
  
  describe "When specifying a contain relationship with default name" do
    before(:all) do
      class Order
        include Neo4j::Node
        properties :date
      end
      
      class Customer
        include Neo4j::Node
        properties :age, :name
        contains :zero_or_more, Order # default name will be orders
      end

    end
    
    it "can add new nodes to that relationship" do
      c = Customer.new
      o = Order.new
      c.orders << o
      
      c.orders.to_a.should include(o)
    end
  end
  
  describe "When creating a relationship" do
    before(:all) do
      class TestNode 
        include Neo4j::Node
      
        relations :friends
      end
    end
    
    it "should allow to set properties on it" do
      t1 = TestNode.new
      t2 = TestNode.new
      
      r = t1.friends.new(t2)
      
      r.friend_since = 1992
      
      r.friend_since.should == 1992
    end
  end

  describe "Deleting a relationship between two nodes" do
    before(:all) do
      class Person
        include Neo4j::Node
        relations :friends
      end
    end    
    
    it "should allow to delate a relationship" do
      p1 = Person.new
      p2 = Person.new
      
      p1.friends << p2
      pending
      
    end
  end
  describe "When a relationship exist between two nodes" do
    before(:all) do
      class TestNode 
        include Neo4j::Node
      
        relations :friends
      end
      
      @t1 = TestNode.new { |n| n.name = 't1'} 
      @t2 = TestNode.new { |n| n.name = 't2'} 
      @t1.friends << @t2
      
      @t21 = TestNode.new { |n| n.name = '21'} 
      @t22 = TestNode.new { |n| n.name = '22'} 
      @t2.friends << @t21 << @t22
    end
    
    it "should allow to filter out nodes" do
      @t1.friends{ name == 't2' }.to_a.should include(@t2)
      @t1.friends{ name == 't1' }.to_a.should_not include(@t2)
    end
    
    it "should allow traverse any depth" do
      pending "depth parameter on traversal should be configurable"
      
      @t1.friends.friends.to_a.should include(@t21, @t22)
      # hmm, not natural that it will include the friends as well and not only friends to friends
      @t1.friends.friends.to_a.size.should == 3 
    end
    
  end  
  
end