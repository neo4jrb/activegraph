require 'neo4j'
require 'neo4j/spec_helper'





# ------------------------------------------------------------------------------
# the following specs are run inside one Neo4j transaction
# 

describe 'Neo4j::Node' do
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

  
  describe '#initialize' do
    after(:each)  do
      undefine_class :TestNode  # must undefine this since each spec defines it
    end
    
    it "should accept no arguments"  do
      class TestNode
        include Neo4j::NodeMixin
      end
      TestNode.new
    end

    it "should allow to initialize itself"  do
      # given an initialize method
      class TestNode
        include Neo4j::NodeMixin
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
        include Neo4j::NodeMixin
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
        include Neo4j::NodeMixin
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
        include Neo4j::NodeMixin
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
      undefine_class :TestNode  # make sure it is not already defined
      class TestNode 
        include Neo4j::NodeMixin
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
  # fire events
  #
  
  describe 'fire events' do 
    before(:all) do
      undefine_class :TestNode  # make sure it is not already defined
      class TestNode
        include Neo4j::NodeMixin
        has_n :orders
        properties :name
      end
      
      undefine_class :TestNode2  # make sure it is not already defined
      class TestNode2
        include Neo4j::NodeMixin
      end
    end
    
    before(:each) do
      TestNode.index_triggers.clear # remove all listeners between tests     
      TestNode2.index_triggers.clear # remove all listeners between tests
    end
    
    
    it "should fire a NodeCreatedEvent when a new node created" do
      # given
      iu = mock('IndexUpdater')
      iu.should_receive(:call).once.with(an_instance_of(TestNode), an_instance_of(Neo4j::NodeCreatedEvent))

      TestNode.index_triggers << iu
      
      # when
      f = TestNode.new
    end
    
    it "should fire a NodeDeletedEvent when a node is deleted" do
      # given
      f = TestNode.new
      
      iu = mock('IndexUpdater')
      iu.should_receive(:call).once.with(f, an_instance_of(Neo4j::NodeDeletedEvent))
      TestNode.index_triggers << iu
      
      # when
      f.delete
    end
    
    it "should fire a PropertyChangedEvent when a property on a node changes" do
      # given
      f = TestNode.new
      iu = mock('IndexUpdater')
      iu.should_receive(:call).once.with(f, an_instance_of(Neo4j::PropertyChangedEvent))            
      TestNode.index_triggers << iu
      
      # when
      f.name = 'foo'
    end


    
    it "should fire a RelationshipDeletedEvent when a relationship between two nodes has been deleted" do
      # given
      cust = TestNode.new
      order = TestNode.new
      cust.orders << order

      iu = mock('IndexUpdater')
      iu.should_receive(:call).once.with(cust, an_instance_of(Neo4j::RelationshipDeletedEvent))   
      TestNode.index_triggers << iu
      
      # when
      cust.relations.outgoing(:orders)[order].delete
      
    end
    

    it "should fire a RelationshipAddedEvent when a new relationship is created to the same class" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new # same class

      iu = mock('IndexUpdater')
      iu.should_receive(:call).once.with(t1, an_instance_of(Neo4j::RelationshipAddedEvent))
      iu.should_receive(:call).once.with(t2, an_instance_of(Neo4j::RelationshipAddedEvent))

      TestNode.index_triggers << iu
      
      # when
      t1.orders << t2
    end

    it "should fire a RelationshipAddedEvent when a new relationship is created to a different class" do
      # given
      t1 = TestNode.new
      t2 = TestNode2.new  # a different class

      iu = mock('IndexUpdater')
      iu.should_receive(:call).once.with(t1, an_instance_of(Neo4j::RelationshipAddedEvent)) 
      TestNode.index_triggers << iu
      
      # when
      t1.orders << t2
    end
    
    it "should fire RelationshipDeletedEvent when a node and its relationships are deleted (same class)" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t1.orders << t2

      iu = mock('IndexUpdater')      
      iu.should_receive(:call).once.with(t2, an_instance_of(Neo4j::NodeDeletedEvent))                              
      iu.should_receive(:call).once.with(t1, an_instance_of(Neo4j::RelationshipDeletedEvent))            
      TestNode.index_triggers << iu      

      # when
      t2.delete
      
      # then
      t1.orders.to_a.size.should == 0 # just to make sure it really was deleted
    end
    
    it "should fire RelationshipDeletedEvent when a node and its relationships are deleted (two different classes)" do
      # given
      iu = mock('IndexUpdater')
      iu.should_receive(:call).once.with(an_instance_of(TestNode), an_instance_of(Neo4j::RelationshipDeletedEvent))      
      t1 = TestNode.new
      t2 = TestNode2.new
      t1.orders << t2
      TestNode.index_triggers << iu      

      # when
      t2.delete
      
      # then
      t1.orders.to_a.size.should == 0 # just to make sure it really was deleted
    end
    
  end
  
end


# ----------------------------------------------------------------------------
# delete
#

describe "Neo4j::Node#delete"  do
  before(:all) do
    start
    undefine_class :TestNode
    class TestNode 
      include Neo4j::NodeMixin
      has_n :friends
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


