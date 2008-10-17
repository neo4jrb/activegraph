require 'neo4j'
require 'neo4j/spec_helper'




describe "Neo4j::Node#relations " do
  before(:all) do
    start
  end

  after(:all) do
    stop
  end  

  
  # ----------------------------------------------------------------------------
  # adding relations with <<
  #
  
  describe '<< operator' do
    
    before(:all) do
      undefine_class :TestNode  # make sure it is not already defined
      
      class TestNode 
        include Neo4j::Node
        has_n :friends
        has_n :parents
      end
    end    
    
    
    it "should add a node to a relation" do
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
  end
  
  # ----------------------------------------------------------------------------
  #  traversing outgoing and incoming nodes
  #
  
  describe '#relations traversing outgoing and incoming nodes' do
    before(:all) do
      undefine_class :TestNode  # make sure it is not already defined
      
      class TestNode 
        include Neo4j::Node
        has_n :friends
        has_n :parents
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

    it "should make sure that incoming nodes are not found in outcoming nodes" do
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

  describe "#has_one" do
    before(:all) do
      undefine_class :Person
      undefine_class :Address
      class Address
      end
      
      class Person
        include Neo4j::Node
        has_one(:address).to(Address)
      end

      class Address
        include Neo4j::Node
        properties :city, :road
        has_n(:people).from(Person, :address)
      end
    end

    it "should create a relationship with assignment like node1.rel = node2" do
      pending
      p = Person.new
      p.address = Address.new {|a| a.city = 'malmoe'; a.road = 'my road'}

      p.address.should be_kind_of(Address)
      p.address.people.to_a.size.should == 1
      p.address.people.to_a.should include(p)
    end
  end

  
  describe "#has_n (A customer contains zero or more orders)" do
    before(:all) do
      class Order
        include Neo4j::Node
        properties :date, :order_id
      end
      
      class CustOrderRel
        include Neo4j::Relation
        properties :my_prop
      end
      
      class Customer
        include Neo4j::Node
        properties :age, :name
        
        # TODO should be easier to say the thing below
        has_n(:orders).relation(CustOrderRel)
      end

    end
    
    it "should contain the order when customer.orders << order" do
      # given
      customer = Customer.new
      order = Order.new
      
      # when
      customer.orders << order
      
      # then
      customer.orders.to_a.should include(order)
    end
    
    it "should allow to set a property on the customer-order relationship" do
      # given
      customer = Customer.new
      order = Order.new
      relation = customer.orders.new(order) # another way of adding a relationship

      # when      
      relation.my_prop = 'a property'

      # then      
      relation.my_prop.should == 'a property'
    end
    
    it "should not contain the order when the customer-order relation has been deleted" do
      # given
      customer = Customer.new
      order = Order.new
      relation = customer.orders.new(order) # another way of adding a relationship
      
      # when
      relation.delete
      
      # then
      customer.orders.to_a.should_not include(order)
    end
    
    it "should find the order using a filter: customer.orders{ order_id == '2'}" do
      # given
      customer = Customer.new
      order1 = Order.new{|n| n.order_id = '1'}
      order2 = Order.new{|n| n.order_id = '2'}
      order3 = Order.new{|n| n.order_id = '3'}
      customer.orders << order1 << order2 << order3
      
      # when
      result = customer.orders{ order_id == '2'}.to_a
      
      # then
      result.should include(order2)
      result.size.should == 1
    end
  end
  
  describe '#relations, creating new' do 
    before(:all) do
      class CustomerOrderRelation
        include Neo4j::Relation
        properties :prio
      end
      
      class Customer
        include Neo4j::Node
        has_n(:orders).relation(CustomerOrderRelation)
        has_n :friends
      end
      
      class Order
        include Neo4j::Node        
      end
    end

    
    it "should be possible to create a new relation of the specified type" do
      c = Customer.new 
      o = Order.new
      r = c.orders.new(o)
      r.should be_kind_of(CustomerOrderRelation)
    end
    
    
    it "should be possible to set a property on relationship (not DynamicRelation)" do
      c = Customer.new 
      o = Order.new
      r = c.orders.new(o)
      r.prio = 'important'
      r.prio.should == 'important'
      
      c.relations.outgoing(:orders)[o].prio.should == 'important'
    end
    
    it "should load the correct relation class when traversing relationships" do
      c = Customer.new 
      o1 = Order.new
      o2 = Order.new
      
      c.orders << o1 << o2
      
      c.relations.outgoing(:orders).each {|r| r.should be_kind_of(CustomerOrderRelation) }
    end
  end
end