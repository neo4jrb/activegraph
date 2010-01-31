$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'spec_helper'


describe Neo4j::RelationshipMixin do
  before(:all) do
    class MyNode
      include Neo4j::NodeMixin
    end

    class MyRel
      include Neo4j::RelationshipMixin
    end
  end

  before(:each) do
    start
    Neo4j::Transaction.new
    @node_a = Neo4j::Node.new
    @node_b = Neo4j::Node.new
  end

  after(:each) do
    Neo4j::Transaction.new
    stop
  end

  it "should have a new method taking 3 arguments: type, from_node, to_node" do
    rel = MyRel.new(:friends, @node_a, @node_b)
    rel.should be_kind_of(MyRel)
  end

  it "should allow to declare properties" do
    MyRel.property :foo
    rel = MyRel.new(:friends, @node_a, @node_b)
    rel.foo = 'hello'
    rel.foo.should == 'hello'
  end

  it "should allow to index relationships" do
    MyRel.property :foo
    MyRel.index :foo
    rel = MyRel.new(:friends, @node_a, @node_b)
    rel.foo = 'hello'
    Neo4j::Transaction.finish

    Neo4j::Transaction.new
    res = MyRel.find(:foo => 'hello')
    res.size.should == 1
    res[0].should == rel
  end

  describe "#end_node and #start_node" do
    before(:all) do
      class MyNodeQ
        include Neo4j::NodeMixin
        property :name
      end
    end
    it "should return the Ruby wrapped Neo4j node" do
      node_end = MyNodeQ.new :name => 'jimmy'
      node_start = Neo4j::Node.new :name => 'james'
      rel = MyRel.new(:friends, node_start, node_end)

      rel.end_node.should be_kind_of(MyNodeQ)
      rel.end_node.name.should == 'jimmy'
      rel.start_node[:name].should == 'james'
    end
  end
end
