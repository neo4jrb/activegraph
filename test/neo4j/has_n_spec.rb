$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'




describe "Neo4j::NodeMixin#has_n " do
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
        include Neo4j::NodeMixin
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

  describe "traversing nodes of arbitrary depth" do
    before(:all) do
      undefine_class :PersonNode
      class PersonNode
        include Neo4j::NodeMixin
        property :name
        has_n :friends
        has_n(:known_by).from(PersonNode, :friends)
      end

      @n0 = PersonNode.new
      @n1 = PersonNode.new
      @n11 = PersonNode.new
      @n111 = PersonNode.new
      @n12 = PersonNode.new
      @n112 = PersonNode.new
      @n1121 = PersonNode.new
      @n0.friends << @n1 << @n12
      @n1.friends << @n11 << @n12
      @n11.friends << @n111 << @n112
      @n112.friends << @n1121
    end

    it "should work with outgoing nodes of depth 2" do
      nodes = @n1.friends.depth(2)
      nodes.should include(@n11,@n12,@n112)
      nodes.should_not include(@n0,@n1,@n1121)
    end

    it "should work with outgoing nodes of depth 3" do
      nodes = @n1.friends.depth(3)
      nodes.should include(@n11,@n12,@n112, @n1121)
      nodes.should_not include(@n0,@n1)
    end

    it "should work with outgoing nodes to the end of graph" do
      nodes = @n1.friends.depth(:all)
      nodes.should include(@n11,@n12,@n112, @n1121)
      nodes.should_not include(@n0,@n1)
    end

    it "should work with incoming nodes of depth 2" do
      nodes = @n1.known_by.depth(2)
      nodes.should include(@n0)
      nodes.to_a.size.should == 1

      nodes = @n11.known_by.depth(2)
      nodes.should include(@n0, @n1)
      nodes.to_a.size.should == 2

      nodes = @n112.known_by.depth(2)
      nodes.should include(@n1, @n11)
      nodes.to_a.size.should == 2
    end

  end

  describe "many to one relationship" do
    before(:all) do
      undefine_class :Customer, :Order, :CustOrderRel

      class Customer; end

      class Order
        include Neo4j::NodeMixin
        property :date, :order_id
        has_one(:customer).from(Customer, :orders)
      end

      class CustOrderRel
        include Neo4j::RelationMixin
        property :my_prop
      end

      class Customer
        include Neo4j::NodeMixin
        property :age, :name

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
      customer.orders.to_a.size == 1
    end

    it "should allow to set the relationship on an incoming node" do
      # given
      customer = Customer.new
      order = Order.new

      # when
      order.customer = customer

      # then
      customer.orders.to_a.should include(order)
      customer.orders.to_a.size == 1
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
#      pending "filter not implemented yet, see ticket 17"
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


  describe 'node1.relation_type.new(node2) (creating a new RelationMixin)' do
    before(:all) do
      class CustomerOrderRelation
        include Neo4j::RelationMixin
        property :prio
      end

      class Customer
        include Neo4j::NodeMixin
        has_n(:orders).relation(CustomerOrderRelation)
        has_n :friends
      end

      class Order
        include Neo4j::NodeMixin
      end
    end


    it "should return a RelationMixin of correct class" do
      # given
      c = Customer.new
      o = Order.new

      # when
      r = c.orders.new(o)

      # then
      r.should be_kind_of(CustomerOrderRelation)
    end

    it "should return a RelationMixin of relationship type" do
      # given
      c = Customer.new
      o = Order.new

      # when
      r = c.orders.new(o)

      # then
      r.relationship_type.should == :orders
    end


    it "should be possible to set a property on the returned relationship" do
      # given
      c = Customer.new
      o = Order.new
      r = c.orders.new(o)

      # when
      r.prio = 'important'

      # then
      r.prio.should == 'important'
      c.relations.outgoing(:orders)[o].prio.should == 'important'
    end

    it "should be possible to read an unset property on the returned RelationMixin" do
      # given
      c = Customer.new
      o = Order.new
      r = c.orders.new(o)

      # when and then
      r.prio.should == nil
    end

    it "should load the created RelationMixin when traversing the relationship" do
      # given
      c = Customer.new
      o1 = Order.new
      o2 = Order.new

      c.orders << o1 << o2

      # when and then
      c.relations.outgoing(:orders).each {|r| r.should be_kind_of(CustomerOrderRelation) }
    end

    it "can not have a relationship to a none Neo::Node" do
      pending "it should raise some sort of Exception"
    end

  end


end