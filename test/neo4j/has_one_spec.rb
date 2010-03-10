$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'spec_helper'


describe "Neo4j::NodeMixin#has_one " do
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
      ExA.has_one(:foo).to(ExB)
      @node = ExA.new
    end

    it "should generate method 'rel' for outgoing nodes in relationships with prefix 'class#rel'" do
      @node.should respond_to(:foo)
    end

    describe "generated method 'rel'" do
      it "should have an '=' operator for adding outgoing nodes of relationship 'class#rel'" do
        # when
        @node.foo = Neo4j::Node.new # it does not have to be of the specified type ExB - no validation is performed

        # then
        @node.rel?('ExB#foo').should be_true
      end

      it "should return the node" do
        node = Neo4j::Node.new
        @node.foo = node
        @node.foo.should == node
      end
    end

    it "should generate method 'rel'_rel" do
      # then
      @node.should respond_to(:foo_rel)
    end

    describe "generated method 'rel'_rels" do
      it "should return the relationship between the nodes" do
        a = Neo4j::Node.new
        @node.foo = a

        # then
        rel = @node.foo_rel
        rel.start_node.should == @node
        rel.end_node.should == a
      end

      it "should returns relationships to nodes of the correct relationship type" do
        a = Neo4j::Node.new
        @node.rels.outgoing(:baaz) << Neo4j::Node.new # make sure this relationship is not returned
        @node.foo = a
        @node.rels.outgoing(:baaz) << Neo4j::Node.new # make sure this relationship is not returned

        # then
        right_rel = @node.rel("ExB#foo")
        @node.foo_rel.should == right_rel
      end
    end
  end
end


describe "Neo4j::NodeMixin#has_one " do
  before(:all) do
    start
    undefine_class :Person, :Address

    class Address
    end

    class Person
      include Neo4j::NodeMixin
      has_one(:address).to(Address)
    end

    class Address
      include Neo4j::NodeMixin
      property :city, :road
      has_n(:people).from(Person, :address)
    end

  end

  before(:each) do
    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish
  end

  it "should create a relationship with assignment, e.g. node1.address = node2" do
    # given
    person = Person.new

    # when
    person.address = Address.new :city => 'malmoe', :road => 'my road'

    # then
    person.address.should be_kind_of(Address)
    [*person.address.people].size.should == 1
    [*person.address.people].should include(person)
  end

  it "should delete previous relationship with new one" do
    # given
    person = Person.new
    address1 = Address.new :city => 'malmoe', :road => 'my road'
    person.address = address1

    # when
    address2 = Address.new :city => 'stockholm', :road => 'new road'
    person.address = address2

    # then
    [*person.rels.outgoing(:"Address#address")].size.should == 1
    person.address.should == address2
  end


  it "should create a relationship with the new method, like node1.rel.new(node2)" do
    # given
    person = Person.new
    address = Address.new {|a| a.city = 'malmoe'; a.road = 'my road'}

    # when
    address.people.new(person)

    # then
    person.address.should be_kind_of(Address)
    [*person.address.people].size.should == 1
    [*person.address.people].should include(person)
  end

  it "should create a relationship with correct relationship type" do
    # given
    person = Person.new
    address = Address.new {|a| a.city = 'malmoe'; a.road = 'my road'}

    # when
    dynamic_relationship = address.people.new(person)

    # then
    dynamic_relationship.relationship_type.should == :"Address#address"
  end

  it "should should return the object using the has_one accessor" do
    a = Address.new
    p = Person.new

    # when
    a.people << p

    # then
    p.address.should == a
  end

end