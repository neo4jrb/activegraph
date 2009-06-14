$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'
require 'extensions/reindexer'

describe "Reindexer (NodeMixin#all)" do

  before(:each)  do
    start
    Neo4j::IndexNode.instance.relationships.each {|r| r.delete unless r.start_node == Neo4j.ref_node}
    undefine_class :TestNode  # must undefine this since each spec defines it
  end

  after(:each) do
    stop
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

  it "should create a referense from the reference node root" do
    class TestNode5
      include Neo4j::NodeMixin
    end

    index_node = Neo4j::IndexNode.instance
    index_node.relationships.outgoing(TestNode5).should be_empty

    # when
    t = TestNode5.new

    # then
    nodes = index_node.relationships.outgoing(TestNode5).nodes
    nodes.to_a.size.should == 1
    nodes.should include(t)
  end


  it "should create a referense from the reference node root for inherited classes" do
    class TestNode6
      include Neo4j::NodeMixin
    end

    class SubNode6 < TestNode6
    end

    index_node = Neo4j::IndexNode.instance
    index_node.relationships.outgoing(TestNode6).should be_empty

    # when
    t = SubNode6.new

    # then
    nodes = index_node.relationships.outgoing(TestNode6).nodes
    nodes.to_a.size.should == 1
    nodes.should include(t)
    SubNode6.root_class.should == TestNode6
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
    B.all.nodes.to_a.should include(a, b)
  end

end
