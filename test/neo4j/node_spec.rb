require 'neo4j'
require 'neo4j/spec_helper'





# ------------------------------------------------------------------------------
# the following specs are run inside one Neo4j transaction
# 

describe Neo4j::Node.to_s do
  before(:all) do
    start
#    @transaction = Neo4j::Transaction.new 
#    @transaction.start
  end

  after(:all) do
#    @transaction.failure # do not want to store anything
#    @transaction.finish
    stop
  end  
 


  # ----------------------------------------------------------------------------
  # initialize
  #

  
  describe 'initialize' do
    after(:each)  do
      undefine_class :TestNode  # must undefine this since each spec defines it
    end
    
    it "should allow constructor with no arguments"  do
      class TestNode
        include Neo4j::Node
      end
      TestNode.new
    end

    it "should allow to initialize itself"  do
      # given an initialize method
      class TestNode
        include Neo4j::Node
        attr_reader :foo 
        def initialize
          @foo = "bar"
        end
      end
      
      # when 
      n = TestNode.new
      
      # then
      n.foo.should == 'bar'
    end
    

    it "should allow arguments for the initialize method"  do
      class TestNode
        include Neo4j::Node
        attr_reader :foo 
        def initialize(value)
          @foo = value
        end
      end
      n = TestNode.new 'hi'
      n.foo.should == 'hi'
    end
    
    it "should allow to create a node from a native Neo Java object" do
      class TestNode
        include Neo4j::Node
      end
      
      node1 = TestNode.new
      node2 = TestNode.new(node1.internal_node)
      node1.internal_node.should == node2.internal_node      
    end
  end

  
  # ----------------------------------------------------------------------------
  # properties
  #
  
  describe '#properties' do
    
    before(:all) do
      undefine_class :TestNode  # make sure it is not already defined
      
      class TestNode 
        include Neo4j::Node
        properties :p1, :p2, :baaz, :foo, :bar, :bar2, :not_set_prop
      end
      @node = TestNode.new
    end

    it "should know which properties has been set" do
      @node.p1 = "val1"
      @node.p2 = "val2"
    
      @node.props.should have_key('p1')
      @node.props.should have_key('p2')
    end
  
    it "should allow to get a property that has not been set" do
      @node.not_set_prop.should be_nil
    end
    
    
    it "should have a neo id property" do
      @node.should respond_to(:neo_node_id)
      @node.neo_node_id.should be_kind_of(Fixnum)
    end

    it "should have a property for the ruby class it represent" do
      @node.classname.should be == TestNode.to_s
    end
    
    it "should allow to set any property" do
      # given
      @node.baaz = "first"
      
      # when
      @node.baaz = "Changed it"
      
      # then
      @node.baaz.should =='Changed it'
    end

    it "should allow to set properties of type Fixnum, Float and Boolean" do
      # when
      @node.baaz = 42
      @node.foo = 3.14
      @node.bar = true
      @node.bar2 = false
      
      # make sure we test that the properties are stored in the neo database
      n = Neo4j::Neo.instance.find_node(@node.neo_node_id)
      
      # then
      n.baaz.should == 42
      n.foo.should == 3.14
      n.bar.should be_true
      n.bar2.should be_false
    end


    it "should generated setter and getters methods" do
      # when
      p = TestNode.new {}
      
      # then
      p.methods.should include('p1','p2','baaz','foo','bar','bar2')
      p.methods.should include("p1=")
    end
    
    it "should automatically be defined on subclasses" do
      undefine_class :SubNode  # make sure it is not already defined
      
      # given
      class SubNode < TestNode
        properties :salary
      end
  
      # when
      p = SubNode.new {}
      
      # then
      p.methods.should include("p1")
      p.methods.should include("p1")
      p.methods.should include("salary")
      p.methods.should include("salary=")
    end

    it "can not have a relationship to a none Neo::Node"
    
    it "can not set a property that is not of type string,fixnum,float or boolean"
   
  end

  # ----------------------------------------------------------------------------
  # equality ==
  #

  describe 'equality (==)' do
    
    before(:all) do
      class TestNode 
        include Neo4j::Node
      end
      NODES = 5
      @nodes = []
      NODES.times {@nodes << TestNode.new}
    end

    it "should be == another node only if it has the same node id" do
      node = TestNode.new(@nodes[0].internal_node)
      node.internal_node.should be_equal(@nodes[0].internal_node)
      node.should == @nodes[0]
      node.hash.should == @nodes[0].hash
    end

    it "should not be == another node only if it has not the same node id" do
      node = TestNode.new(@nodes[1].internal_node)
      node.internal_node.should_not be_equal(@nodes[0].internal_node)
      node.should_not == @nodes[0]
      node.hash.should_not == @nodes[0].hash
    end
    
  end
  


  # ----------------------------------------------------------------------------
  # event listeners
  #
  
  describe 'event listeners' do
    before(:all) do
      undefine_class :TestNode  # make sure it is not already defined
      undefine_class :ChildTestNode  
      undefine_class :NotChildTestNode
      
      class TestNode 
        include Neo4j::Node
      end
      class ChildTestNode < TestNode
      end
      class NotChildTestNode 
        include Neo4j::Node
      end
    end
    
    before(:each) do
      TestNode.listeners.clear # remove all listeners between tests     
    end
    
    it "should be shared by subclasses" do
      # when adding a listener
      TestNode.listeners << 'a'
      
      # then both Test Listener
      TestNode.listeners.size.should == 1
      TestNode.listeners[0].should == 'a'
      ChildTestNode.listeners.size.should == 1      
      ChildTestNode.listeners[0].should == 'a'      
      NotChildTestNode.listeners.size.should == 0
      
      ChildTestNode.listeners << 'b'
      TestNode.listeners.size.should == 2
      TestNode.listeners[1].should == 'b'
      NotChildTestNode.listeners.size.should == 0      
    end
    
    
    it "can be removed" do
      listener = TestNode.add_listener {}

      TestNode.remove_listener(listener)
      TestNode.listeners.size.should == 0
    end
    
    it "can be added" do
      listener = TestNode.add_listener {}
      
      TestNode.listeners.size.should == 1
      TestNode.listeners.should include(listener)
    end
  end
  
  
  # ----------------------------------------------------------------------------
  # fire events
  #
  
  describe 'fire events' do 
    before(:all) do
      class Customer
        include Neo4j::Node
        relations :orders
        properties :name
      end
      
      class Order
        include Neo4j::Node        
      end
    end
    
    before(:each) do
      Customer.listeners.clear # remove all listeners between tests     
      Order.listeners.clear # remove all listeners between tests     
    end
    
    
    it "should fire a NodeCreatedEvent when a new node created" do
      # given
      events = []
      Customer.add_listener {|event| events << event}
      
      # when
      f = Customer.new
      
      # then
      events.size.should == 1
      events[0].should be_kind_of(Neo4j::NodeCreatedEvent)
      events[0].node.should == f
    end
    
    it "should fire a NodeDeletedEvent when a node is deleted" do
      # given
      f = Customer.new
      events = []
      Customer.add_listener {|event| events << event}
      
      # when
      f.delete
      
      # then
      events.size.should == 1
      events[0].should be_kind_of(Neo4j::NodeDeletedEvent)
      events[0].node.should == f
    end
    
    it "should fire a PropertyChangedEvent when a property on a node changes" do
      # given
      f = Customer.new
      events = []
      Customer.add_listener {|event| events << event}
      
      # when
      f.name = 'foo'
      
      # then
      events.size.should == 1
      events[0].should be_kind_of(Neo4j::PropertyChangedEvent)
      events[0].property.should == :name
      events[0].old_value.should == nil
      events[0].new_value.should == 'foo'
      events[0].node.should == f
    end


    
    it "should fire a RelationshipDeletedEvent when a relationship between two nodes has been deleted" do
      # given
      cust = Customer.new
      order = Order.new
      cust.orders << order

      events = []
      Customer.add_listener {|event| events << event}
      
      # when
      cust.relations.outgoing(:orders)[order].delete
      
      # then
      cust.orders.to_a.size.should == 0 # just to make sure it really was deleted
      events.size.should == 1
      events[0].should be_kind_of(Neo4j::RelationshipDeletedEvent)
    end
    

    it "should fire a RelationshipAddedEvent when a new relationship is created" do
      # given
      events = []
      Customer.add_listener {|event| events << event}
      
      cust = Customer.new
      order = Order.new
      
      # when
      cust.orders << order
      
      # then
      events.size.should == 2
      events[0].should be_kind_of(Neo4j::NodeCreatedEvent)
      events[1].should be_kind_of(Neo4j::RelationshipAddedEvent)
      events[1].node.should == cust
      events[1].to_node.should == order
      events[1].relation_name.should == 'orders'
    end
    
    it "should fire RelationshipDeletedEvent when a node and its relationships are deleted" do
      pending
      # given
      events = []
      Customer.add_listener {|event| events << event}
      
      cust = Customer.new
      order = Order.new
      cust.orders << order
      
      # when
      order.delete
      
      # then
      cust.orders.to_a.size.should == 0 # just to make sure it really was deleted
      events.size.should == 1
      events[0].should be_kind_of(Neo4j::RelationshipDeletedEvent)
    end
  end
  
end


# ----------------------------------------------------------------------------
# delete
#

describe Neo4j::Node.to_s, 'delete'  do
  before(:all) do
    start
    class TestNode 
      include Neo4j::Node
      relations :friends
    end

  end
    
  after(:all) do
    stop
  end
  
  it "should delete all relationships as well" do
    # given
    t1 = TestNode.new
    t2 = TestNode.new { |n| n.friends << t1}
      
    # when
    t1.delete
    
    # then
    t2.friends.to_a.should_not include(t1)      
  end
end


