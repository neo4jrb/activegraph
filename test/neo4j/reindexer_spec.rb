$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'
require 'neo4j/extensions/reindexer'



class ReindexerTestNode
  include Neo4j::NodeMixin
  property :name, :age
end

class ReindexerTestNode2
  include Neo4j::NodeMixin
end

describe "Reindexer (NodeMixin#all)" do

  before(:each)  do
    start
    Neo4j.load_reindexer
    Neo4j::Transaction.new

    Neo4j::IndexNode.instance.relationships.each {|r| r.delete unless r.start_node == Neo4j.ref_node}
    undefine_class :TestNode  # must undefine this since each spec defines it
  end

  after(:each) do
    Neo4j::Transaction.finish
    stop
  end

  before(:all) do
    Neo4j.event_handler.add(Neo4j::IndexNode) # incase it has been disabled by an RSpec
  end

  after(:all) do
    Neo4j.event_handler.remove(Neo4j::IndexNode) # avoid side effects on using this extension
  end


  it "has a reference to a created node" do
    #should only have a reference to the reference node
    n = ReindexerTestNode.new
    n.name = 'hoj'

    # then
    Neo4j::IndexNode.instance.relationships.nodes.should include(n)
    Neo4j::IndexNode.instance.relationships.to_a.size.should == 1
  end

  it "has a reference to all created nodes" do
    Neo4j::IndexNode.instance.relationships.outgoing.to_a.should be_empty
    node1 = ReindexerTestNode.new
    node2 = ReindexerTestNode2.new
    node3 = ReindexerTestNode2.new

    # then
    Neo4j::IndexNode.instance.relationships.outgoing(:ReindexerTestNode).nodes.should include(node1)
    Neo4j::IndexNode.instance.relationships.outgoing(:ReindexerTestNode2).nodes.should include(node2, node3)
    Neo4j::IndexNode.instance.relationships.outgoing(:ReindexerTestNode).nodes.to_a.size.should == 1
    Neo4j::IndexNode.instance.relationships.outgoing(:ReindexerTestNode2).nodes.to_a.size.should == 2

    ReindexerTestNode.all.nodes.to_a.size.should == 1
    ReindexerTestNode2.all.nodes.to_a.size.should == 2
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



describe "Reindex" do
  it "should reindex nodes after the neo4j has restarted (lighthouse ticket #53)" do
    Neo4j.load_reindexer # since a previous test might have unloaded this extension
    
    undefine_class :TestNode
    class TestNode
      include Neo4j::NodeMixin
      property :name, :age
      index :name
    end

    Neo4j::Transaction.new
    Neo4j.start
    t1 = TestNode.new
    t1.name = 't1'
    Neo4j::Transaction.finish


    # make sure we can find it
    Neo4j::Transaction.new
    TestNode.all.nodes.to_a.should include(t1)
    Neo4j::Transaction.finish

    # now restart neo and check if neo4j still keep track of all created nodes
    Neo4j.stop
    Neo4j.start

    # create another node check if still works
    Neo4j::Transaction.new
    Neo4j.start
    t2 = TestNode.new
    t2.name = 't2'
    Neo4j::Transaction.finish


    # make sure we can find it
    Neo4j::Transaction.new
    TestNode.all.nodes.to_a.should include(t2)
    Neo4j::Transaction.finish

  end
end


