$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'



describe 'NodeMixin' do
  before(:all) do
    start
  end

  after(:all) do
    stop
  end  
 
  # ----------------------------------------------------------------------------
  # initialize
  #
  
  describe '#initialize' do
    before(:each)  do
      stop
      undefine_class :TestNode, :SubNode  # must undefine this since each spec defines it
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

    it "should create a referense from the reference node root" do
      class TestNode
        include Neo4j::NodeMixin
      end

      ref_node = Neo4j.instance.ref_node
      ref_node.relations.outgoing(TestNode).should be_empty

      # when
      t = TestNode.new
      
      # then
      nodes = ref_node.relations.outgoing(TestNode).nodes
      nodes.to_a.size.should == 1
      nodes.should include(t)
    end

    it "should create a referense from the reference node root for inherited classes" do
      class TestNode
        include Neo4j::NodeMixin
      end
      
      class SubNode < TestNode
      end

      ref_node = Neo4j.instance.ref_node
      ref_node.relations.outgoing(TestNode).should be_empty

      # when
      t = SubNode.new

      # then
      nodes = ref_node.relations.outgoing(TestNode).nodes
      nodes.to_a.size.should == 1
      nodes.should include(t)
      SubNode.root_class.should == TestNode.to_s
    end
  end


  # ----------------------------------------------------------------------------
  # update
  #

  describe '#update' do
    before(:all)  do
      undefine_class :TestNode
      class TestNode
        include Neo4j::NodeMixin
        property :name, :age
      end
    end

    it "should be able to update a node from a value obejct" do
      # given
      t = TestNode.new
      t.name='kalle'
      t.age=2
      vo = t.value_object
      t2 = TestNode.new
      t2.name = 'foo'

      # when
      t2.update(vo)

      # then
      t2.name.should == 'kalle'
      t2.age.should == 2
    end

    it "should be able to update a node by using a hash even if the keys in the hash is not a declarared property" do
      t = TestNode.new
      t.update({:name=>'123', :oj=>'hoj'})
      t.name.should == '123'
      t.age.should == nil
    end

    it "should be able to update a node by using a hash" do
      t = TestNode.new
      t.update({:name=>'andreas', :age=>3})
      t.name.should == 'andreas'
      t.age.should == 3
    end

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
        property :name
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

      TestNode.index_triggers['foo'] = iu
      
      # when
      f = TestNode.new
    end
    
    it "should fire a NodeDeletedEvent when a node is deleted" do
      # given
      f = TestNode.new
      
      iu = mock('IndexUpdater')
      iu.should_receive(:call).once.with(f, an_instance_of(Neo4j::NodeDeletedEvent))
      TestNode.index_triggers['foo'] = iu
      
      # when
      f.delete
    end

    it "should fire a PropertyChangedEvent when a property on a node changes" do
      # given
      f = TestNode.new
      iu = mock('IndexUpdater')
      iu.should_receive(:call).once.with(f, an_instance_of(Neo4j::PropertyChangedEvent))            
      TestNode.index_triggers['foo'] = iu
      
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
      TestNode.index_triggers['foo'] = iu
      
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

      TestNode.index_triggers['foo'] = iu
      
      # when
      t1.orders << t2
    end

    it "should fire a RelationshipAddedEvent when a new relationship is created to a different class" do
      # given
      t1 = TestNode.new
      t2 = TestNode2.new  # a different class

      iu = mock('IndexUpdater')
      iu.should_receive(:call).once.with(t1, an_instance_of(Neo4j::RelationshipAddedEvent)) 
      TestNode.index_triggers['foo'] = iu
      
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
      TestNode.index_triggers['foo'] = iu

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
      TestNode.index_triggers['foo'] = iu

      # when
      t2.delete
      
      # then
      t1.orders.to_a.size.should == 0 # just to make sure it really was deleted
    end
    
  end


  # ----------------------------------------------------------------------------
  # all
  #
  describe 'Neo4j::Node#all' do
    before(:each)  do
      Neo4j.instance.ref_node.relations.each {|r| r.delete}
      undefine_class :TestNode  # must undefine this since each spec defines it
    end

    it "should return all node instances" do
      class TestNode
        include Neo4j::NodeMixin
      end

      t1 = TestNode.new
      t2 = TestNode.new

      # when
      TestNode.all.to_a.size.should == 2
      TestNode.all.nodes.to_a.should include(t1)
      TestNode.all.nodes.to_a.should include(t2)
    end


    it "should not return deleted node instances" do
      class TestNode
        include Neo4j::NodeMixin
      end

      t1 = TestNode.new
      t2 = TestNode.new
      TestNode.all.to_a.size.should == 2

      # when
      t1.delete
      TestNode.all.to_a.size.should == 1
      TestNode.all.nodes.to_a.should include(t2)
    end

    it "should return subclasses instances as well" do
      class A
        include Neo4j::NodeMixin
      end

      class B < A
      end

      # when
      a = A.new
      b = B.new

      # then
      A.all.to_a.size.should == 2
      B.all.nodes.to_a.should include(a,b)
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



