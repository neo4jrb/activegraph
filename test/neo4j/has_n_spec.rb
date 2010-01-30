$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'spec_helper'


describe "Neo4j::NodeMixin#has_n " do
  class ExA
    include Neo4j::NodeMixin
  end

  class ExB
    include Neo4j::NodeMixin
  end

  before(:all) do
    start
  end

  before(:each) do
    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish
  end


  describe "(rel).to(class)" do
    before (:each) do
      # given
      ExA.has_n(:foo).to(ExB)
      @node = ExA.new
    end

    it "should generate method 'rel' for outgoing nodes in relationships with prefix 'class#rel'" do
      @node.should respond_to(:foo)
    end

    describe "generated method 'rel'" do
      it "should have an '<<' operator for adding outgoing nodes of relationship 'class#rel'" do
        # when
        @node.foo << Neo4j::Node.new # it does not have to be of the specified type ExB - no validation is performed

        # then
        @node.rel?('ExB#foo').should be_true
      end

      it "should be of type Enumerable" do
        @node.foo.should be_kind_of(Enumerable)
      end

      it "should contain all nodes that has been added using the << operator" do
        a = Neo4j::Node.new
        b = Neo4j::Node.new
        @node.foo << a << b

        # then
        @node.foo.should include(a, b)
      end
    end

    it "should generate method 'rel'_rels" do
      # then
      @node.should respond_to(:foo_rels)
    end

    describe "generated method 'rel'_rels" do
      it "should be of type Enumerable" do
        @node.foo_rels.should be_kind_of(Enumerable)
      end

      it "should return the relationship between the nodes" do
        a = Neo4j::Node.new
        @node.foo << a

        # then
        [*@node.foo_rels].size.should == 1
        rel = @node.foo_rels.first
        rel.start_node.should == @node
        rel.end_node.should == a
      end

      it "should only returns relationships to nodes of the correct relationship type" do
        a = Neo4j::Node.new
        @node.foo << a
        @node.rels.outgoing(:baaz) << Neo4j::Node.new # make sure this relationship is not returned

        # then
        [*@node.foo_rels].size.should == 1
        wrong_rel = @node.rel(:baaz)
        right_rel = @node.rel("ExB#foo")

        @node.foo_rels.should_not include(wrong_rel)
        @node.foo_rels.should include(right_rel)
      end

      it "should include all the relationships of the declared has_n type" do
        a = Neo4j::Node.new
        b = Neo4j::Node.new
        c = Neo4j::Node.new
        @node.foo << a << b << c
        r_a = a.rel("ExB#foo", :incoming)
        r_b = a.rel("ExB#foo", :incoming)
        r_c = a.rel("ExB#foo", :incoming)

        # then
        @node.foo_rels.should include(r_a, r_b, r_c)
      end
    end
  end

  describe "(rel).from(class)" do
    before(:each) do
      ExB.has_n(:baaz)
      ExA.has_n(:baaz).from(ExB)
    end
    it "should generate method 'rel' for outgoing relationships with no prefix from the other node" do
      # when
      a = ExA.new
      b = ExB.new
      a.baaz << b # add relationship on ExB to ExA !

      # then
      b.rel?('baaz').should be_true
    end

    it "should generate method 'rel'_rels returning incoming relationships" do
      # when
      a = ExA.new
      b = ExB.new
      a.baaz << b # add relationship on ExB to ExA !
      [*a.baaz_rels].size.should == 1
      rel = b.rel(:baaz)
      a.baaz_rels.should include(rel)
    end
  end

  describe "(rel).from(class, rel2)" do
    it "should generate relationships with no prefix from the other node" do
      # given
      ExB.has_n(:foobar)
      ExA.has_n(:hoj).from(ExB, :foobar)

      # when
      a = ExA.new
      b = ExB.new
      a.hoj << b # add relationship on ExB to ExA !

      # then
      b.rel?('foobar').should be_true
    end
  end

  describe "(rel).from(class) AND class has namespaced its relationship" do
    before(:each) do
      ExB.has_n(:baaz).to(ExA) # Add namespace ExA to the relationship
      ExA.has_n(:baaz).from(ExB)
    end
    it "should generate method 'rel' for outgoing relationships WITH prefix from the other node" do
      # when
      a = ExA.new
      b = ExB.new
      a.baaz << b # add relationship on ExB to ExA !

      # then
      b.rel?('ExA#baaz').should be_true
    end

    it "should generate method 'rel'_rels returning incoming relationships" do
      # when
      a = ExA.new
      b = ExB.new
      a.baaz << b # add relationship on ExB to ExA !
      [*a.baaz_rels].size.should == 1
      rel = b.rel('ExA#baaz')
      a.baaz_rels.should include(rel)
    end
  end

  describe "(rel).from(class, rel2) and class has namespaced its relationship" do
    it "should generate relationships WITH prefix from the other node" do
      # given
      ExB.has_n(:foobar).to(ExA) # add namespace ExA
      ExA.has_n(:hoj).from(ExB, :foobar)

      # when
      a = ExA.new
      b = ExB.new
      a.hoj << b # add relationship on ExB to ExA !

      # then
      b.rel?('ExA#foobar').should be_true
    end
  end

  # ----------------------------------------------------------------------------
  # adding relationships with <<
  #

  describe '<< operator' do

    before(:all) do
      undefine_class :TestNode # make sure it is not already defined

      class TestNode
        include Neo4j::NodeMixin
        has_n :friends
        has_n :parents
      end
    end


    it "should add a node to a relationship" do
      t1 = TestNode.new
      t2 = TestNode.new

      # when
      t1.friends << t2

      # then
      [*t1.friends].should include(t2)
    end

    it "should add relationships of different types to other nodes" do
      me = TestNode.new
      f1 = TestNode.new
      p1 = TestNode.new
      me.friends << f1
      me.parents << p1

      # then
      [*me.friends].should include(f1)
      [*me.friends].size.should == 1
      [*me.parents].should include(p1)
      [*me.parents].size.should == 1
    end

    it "should be none symmetric (if a is friend to b then b does not have to be friend to a)" do
      t1 = TestNode.new
      t2 = TestNode.new
      t1.friends << t2

      # then
      [*t1.friends].should include(t2)
      [*t2.friends].should_not include(t1)
    end

    it "should allow to chain << operations in one line" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t3 = TestNode.new
      t1.friends << t2 << t3

      # then t2 should be a friend of t1
      [*t1.friends].should include(t2, t3)
    end


    it "should be allowed in subclasses" do
      undefine_class :SubNode # make sure it is not already defined
      class SubNode < TestNode;
      end
      sub = SubNode.new
      t = TestNode.new
      sub.friends << t

      # then
      [*sub.friends].should include(t)
    end
  end

  describe "traversing nodes of arbitrary depth" do
    before(:all) do
      undefine_class :PersonNode
      class PersonNode
        include Neo4j::NodeMixin
        property :name
        has_n(:friends).to(PersonNode)
        has_n(:known_by).from(PersonNode, :friends)
      end

      Neo4j::Transaction.run do
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
    end

    it "should work with outgoing nodes of depth 2" do
      nodes = @n1.friends.depth(2)
      nodes.should include(@n11, @n12, @n112)
      nodes.should_not include(@n0, @n1, @n1121)
    end

    it "should work with outgoing nodes of depth 3" do
      nodes = @n1.friends.depth(3)
      nodes.should include(@n11, @n12, @n112, @n1121)
      nodes.should_not include(@n0, @n1)
    end

    it "should work with outgoing nodes to the end of graph" do
      nodes = @n1.friends.depth(:all)
      nodes.should include(@n11, @n12, @n112, @n1121)
      nodes.should_not include(@n0, @n1)
    end

    it "should work with incoming nodes of depth 2" do
      nodes = @n1.known_by.depth(2)
      nodes.should include(@n0)
      [*nodes].size.should == 1

      nodes = @n11.known_by.depth(2)
      nodes.should include(@n0, @n1)
      [*nodes].size.should == 2

      nodes = @n112.known_by.depth(2)
      nodes.should include(@n1, @n11)
      [*nodes].size.should == 2
    end

  end

  describe "many to one relationship" do
    before(:all) do
      undefine_class :Customer, :Order, :CustOrderRel

      class Customer;
      end

      class Order
        include Neo4j::NodeMixin
        property :date, :order_id
        has_one(:customer).from(Customer, :orders)

        def to_s
          "Order #{order_id}"
        end
      end

      class CustOrderRel
        include Neo4j::RelationshipMixin
        property :my_prop
      end

      class Customer
        include Neo4j::NodeMixin
        property :age, :name

        has_n(:orders).relationship(CustOrderRel)
      end

    end

    it "should contain the order when customer.orders << order" do
      # given
      customer = Customer.new
      order = Order.new

      # when
      customer.orders << order

      # then
      [*customer.orders].should include(order)
      [*customer.orders].size == 1
    end

    it "should allow to set the relationship on an incoming node" do
      # given
      customer = Customer.new
      order = Order.new

      # when
      order.customer = customer

      # then
      [*customer.orders].should include(order)
      [*customer.orders].size == 1
    end

    it "should allow to set a property on the customer-order relationship" do
      # given
      customer = Customer.new
      order = Order.new
      relationship = customer.orders.new(order) # another way of adding a relationship

      # when
      relationship.my_prop = 'a property'

      # then
      relationship.my_prop.should == 'a property'
    end

    it "should not contain the order when the customer-order relationship has been deleted" do
      # given
      customer = Customer.new
      order = Order.new
      relationship = customer.orders.new(order) # another way of adding a relationship

      # when
      relationship.del

      # then
      [*customer.orders].should_not include(order)
    end

    it "should find the order using a filter: customer.orders{ order_id == '2'}" do
#      pending "filter not implemented yet, see ticket 17"
      # given
      customer = Customer.new
      order1 = Order.new
      order2 = Order.new
      order3 = Order.new
      customer.orders << order1 << order2 << order3

      order1.order_id = '1'
      order2.order_id = '2'
      order3.order_id = '3'

      # when
      result = [*customer.orders{ order_id == '2'}]

      # then
      result.should include(order2)
      result.size.should == 1
    end
  end


  describe 'node1.<relationship_type>.new(node2) (creating a new RelationshipMixin)' do
    before(:all) do
      class CustomerOrderRelationship
        include Neo4j::RelationshipMixin
        property :prio
      end

      class Customer
        include Neo4j::NodeMixin
        has_n(:orders).relationship(CustomerOrderRelationship)
        has_n :friends
      end

      class Order
        include Neo4j::NodeMixin
      end
    end


    it "should return a RelationshipMixin of correct class" do
      # given
      c = Customer.new
      o = Order.new

      # when
      r = c.orders.new(o)

      # then
      r.should be_kind_of(CustomerOrderRelationship)
    end

    it "should return a RelationshipMixin of relationship type" do
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
      c.rels.outgoing(:orders)[o].prio.should == 'important'
    end

    it "should be possible to read an unset property on the returned RelationshipMixin" do
      # given
      c = Customer.new
      o = Order.new
      r = c.orders.new(o)

      # when and then
      r.prio.should == nil
    end

    it "should load the created RelationshipMixin when traversing the relationship" do
      # given
      c = Customer.new
      o1 = Order.new
      o2 = Order.new

      c.orders << o1 << o2

      # when and then
      c.rels.outgoing(:orders).each {|r| r.should be_kind_of(CustomerOrderRelationship) }
    end

    it "can not have a relationship to a none Neo::Node" do
      pending "it should raise some sort of Exception"
    end

  end


end