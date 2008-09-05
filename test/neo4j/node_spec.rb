require 'neo4j'
require 'neo4j/spec_helper'





# ------------------------------------------------------------------------------
# the following specs are run inside one Neo4j transaction
# 

describe Neo4j::Node.to_s do
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
  
  describe 'properties' do
    
    before(:all) do
      undefine_class :TestNode  # make sure it is not already defined
      
      class TestNode 
        include Neo4j::Node
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
  # declared properties
  #
  
  describe 'declared properties' do
    before(:all) do
      undefine_class :TestNode  # make sure it is not already defined
      class TestNode 
        include Neo4j::Node
        properties :my_property        
      end
    end    
    
    it "should generated setter and getters methods" do
      # when
      p = TestNode.new {}
      
      # then
      p.methods.should include("my_property")
      p.methods.should include("my_property=")
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
      p.methods.should include("my_property")
      p.methods.should include("my_property=")
      p.methods.should include("salary")
      p.methods.should include("salary=")
    end
    
  end
  
  
  # ----------------------------------------------------------------------------
  # adding relations with <<
  #
  
  describe 'adding relations with <<' do
    
    before(:all) do
      undefine_class :TestNode  # make sure it is not already defined
      
      class TestNode 
        include Neo4j::Node
        relations :friends
        relations :parents
      end
    end    
    
    it "should also work with dynamically defined relation types" do
      # given
      node = TestNode.new
      
      # when
      TestNode.add_relation_type(:foos)
      
      # then
      added = Neo4j::BaseNode.new
      node.foos << added
      node.foos.to_a.should include(added)
    end

    
    it "should add a relation of a specific type to another node" do
      t1 = TestNode.new
      t2 = TestNode.new
      
      # when
      t1.friends << t2

      # then
      t1.friends.to_a.should include(t2)
    end
    
    it "should add relations of different types to other nodes" do
      me = TestNode.new
      f1 = TestNode.new
      p1 = TestNode.new
      me.friends << f1
      me.parents << p1

      # then
      me.friends.to_a.should include(f1)
      me.friends.to_a.size.should == 1
      me.parents.to_a.should include(p1)
      me.parents.to_a.size.should == 1
    end

    it "should be none symmetric (if a is friend to b then b does not have to be friend to a)" do
      t1 = TestNode.new
      t2 = TestNode.new
      t1.friends << t2

      # then
      t1.friends.to_a.should include(t2)
      t2.friends.to_a.should_not include(t1)      
    end
    
    it "should allow to chain << operations in one line" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t3 = TestNode.new
      t1.friends << t2 << t3
      
      # then t2 should be a friend of t1
      t1.friends.to_a.should include(t2,t3)
    end


    it "should be allowed in subclasses" do
      undefine_class :SubNode  # make sure it is not already defined
      class SubNode < TestNode; end
      sub = SubNode.new
      t = TestNode.new
      sub.friends << t

      # then
      sub.friends.to_a.should include(t)
    end

    # ----------------------------------------------------------------------------
    # finding relationships
    #
  
    describe 'finding relationships' do
      before(:all) do
        undefine_class :TestNode  # make sure it is not already defined
      
        class TestNode 
          include Neo4j::Node
          relations :friends
          relations :parents
        end
      end    
    
      it "should find all outgoing nodes" do
        # given
        t1 = TestNode.new
        t2 = TestNode.new
        t1.friends << t2

        # when
        outgoing = t1.relations.outgoing.to_a
      
        # then
        outgoing.size.should == 1
        outgoing[0].end_node.should == t2
        outgoing[0].start_node.should == t1
      end
    
      it "should find all incoming nodes" do
        t1 = TestNode.new
        t2 = TestNode.new
      
        t1.friends << t2
      
        outgoing = t2.relations.incoming.to_a
        outgoing.size.should == 1
        outgoing[0].end_node.should == t2
        outgoing[0].start_node.should == t1
      end

      it "should find no incoming or outgoing nodes when there are none" do
        t1 = TestNode.new
        t2 = TestNode.new
      
        t2.relations.incoming.to_a.size.should == 0
        t2.relations.outgoing.to_a.size.should == 0
      end

      it "should incoming nodes should not be found in outcoming nodes" do
        t1 = TestNode.new
        t2 = TestNode.new
      
        t1.friends << t2
        t1.relations.incoming.to_a.size.should == 0
        t2.relations.outgoing.to_a.size.should == 0
      end


      it "should find both incoming and outgoing nodes" do
        t1 = TestNode.new
        t2 = TestNode.new
      
        t1.friends << t2
        t1.relations.nodes.to_a.should include(t2)
        t2.relations.nodes.to_a.should include(t1)
      end

      it "should find several both incoming and outgoing nodes" do
        t1 = TestNode.new
        t2 = TestNode.new
        t3 = TestNode.new
            
        t1.friends << t2
        t1.friends << t3
      
        t1.relations.nodes.to_a.should include(t2,t3)
        t1.relations.outgoing.nodes.to_a.should include(t2,t3)      
        t2.relations.incoming.nodes.to_a.should include(t1)      
        t3.relations.incoming.nodes.to_a.should include(t1)      
        t1.relations.nodes.to_a.size.should == 2
      end
    
      it "should find incomming nodes of a specific type" do
        t1 = TestNode.new
        t2 = TestNode.new
        t3 = TestNode.new
            
        t1.friends << t2
        t1.friends << t3
      
        t1.relations.outgoing(:friends).nodes.to_a.should include(t2,t3)      
        t2.relations.incoming(:friends).nodes.to_a.should include(t1)      
        t3.relations.incoming(:friends).nodes.to_a.should include(t1)      
      end
    end


    # ----------------------------------------------------------------------------
    # event listeners
    #
  
    describe 'event listeners' do
      before(:all) do
        class FooNode 
          include Neo4j::Node
        end
      end
    
      before(:each) do
        FooNode.listeners.clear # remove all listeners between tests     
      end
    
      it "should be shared by subclasses" do
        class BaazNode
          include Neo4j::Node
          relations :people
        end

        class FooChildNode < FooNode
        end
      
        FooNode.listeners << 'a'
        FooNode.listeners.size.should == 1
        FooNode.listeners[0].should == 'a'
        FooChildNode.listeners.size.should == 1      
        FooChildNode.listeners[0].should == 'a'      
        BaazNode.listeners.size.should == 0
      
        FooChildNode.listeners << 'b'
        FooNode.listeners.size.should == 2
        FooNode.listeners[1].should == 'b'
      end
    
    
      it "can be removed" do
        listener = FooNode.add_listener {|event| puts event}

        FooNode.remove_listener(listener)
        FooNode.listeners.size.should == 0
      end
    
      it "can be added" do
        listener = FooNode.add_listener {|event| puts event}
      
        FooNode.listeners.size.should == 1
        FooNode.listeners.should include(listener)
      end
    end
  
  
    # ----------------------------------------------------------------------------
    # property events
    #
  
    describe 'NodeCreatedEvent' do # TODO split up into several describe blocks, one for each event type
      before(:all) do
        class FooNode 
          include Neo4j::Node
        end
      end
    
      before(:each) do
        FooNode.listeners.clear # remove all listeners between tests     
      end
    
    
      it "should notify event listener for new node created" do
        # given
        events = []
        FooNode.add_listener {|event| events << event}
      
        # when
        f = FooNode.new
      
        # then
        events.size.should == 1
        events[0].should be_kind_of(Neo4j::NodeCreatedEvent)
        events[0].node.should == f
      end
    
      it "should notify event listener when a new relationship is created" 
    
      it "should notify event listener when a relationship between two nodes has been deleted" do
        pending 
        # given
        class ANode
          include Neo4j::Node
          relations :bnodes
        end
        class BNode
          include Neo4j::Node
        end
      
        a = ANode.new
        b = BNode.new
        a.bnodes << b

        ANode.listeners.clear # remove all listeners between tests
        events = []
        ANode.add_listener {|event| events << event}
      
        # when
        a.relations.outgoing(:bnodes)[b].delete
      
        # then
        a.bnodes.to_a.size.should == 0 # just to make sure it really was deleted
        events.size.should == 1
        events[0].should be_kind_of(RelationshipDeletedEvent)
      end
    
      it "should notify event listener for node deleted" 
    
      it "should notify event listener for property change events" do
        # given
        f = FooNode.new
        events = []
        FooNode.add_listener {|event| events << event}
      
        # when
        f.foo = 'foo'
      
        # then
        events.size.should == 1
        events[0].should be_kind_of(Neo4j::PropertyChangedEvent)
        events[0].property.should == :foo
        events[0].old_value.should == nil
        events[0].new_value.should == 'foo'
        events[0].node.should == f
      end
    end

    # ----------------------------------------------------------------------------
    # relationship events
    #

    describe 'relationship events' do
      before(:all) do
        class Customer
          include Neo4j::Node
          relations :orders
        end
      
        class Order
          include Neo4j::Node        
        end
      end
    
      before(:each) do
        Customer.listeners.clear # remove all listeners between tests     
        Order.listeners.clear # remove all listeners between tests     
      end
    
      it "should notify event listener when a new relationship is created" do
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


