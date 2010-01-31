$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'spec_helper'



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
    Neo4j::Transaction.new
    Neo4j::IndexNode.instance.rels.each {|r| r.del unless r.start_node == Neo4j.ref_node}
    undefine_class :TestNode  # must undefine this since each spec defines it
  end

  after(:each) do
    Neo4j::Transaction.finish
    stop
  end

  before(:all) do
    require 'neo4j/extensions/reindexer'
    Neo4j.load_reindexer
  end

  after(:all) do
    Neo4j.unload_reindexer
  end


  it "has a reference to a created node" do
    #should only have a reference to the reference node
    n = ReindexerTestNode.new
    n.name = 'hoj'

    # then
    Neo4j::IndexNode.instance.rels.nodes.should include(n)
    [*Neo4j::IndexNode.instance.rels].size.should == 1
  end

  it "has a reference to all created nodes" do
    [*Neo4j::IndexNode.instance.rels.outgoing].should be_empty
    node1 = ReindexerTestNode.new
    node2 = ReindexerTestNode2.new
    node3 = ReindexerTestNode2.new

    # then
    Neo4j::IndexNode.instance.rels.outgoing(:ReindexerTestNode).nodes.should include(node1)
    Neo4j::IndexNode.instance.rels.outgoing(:ReindexerTestNode2).nodes.should include(node2, node3)
    [*Neo4j::IndexNode.instance.rels.outgoing(:ReindexerTestNode).nodes].size.should == 1
    [*Neo4j::IndexNode.instance.rels.outgoing(:ReindexerTestNode2).nodes].size.should == 2

    [*ReindexerTestNode.all.nodes].size.should == 1
    [*ReindexerTestNode2.all.nodes].size.should == 2
  end

  it "should return all node instances" do
    class TestNode
      include Neo4j::NodeMixin
    end

    t1 = TestNode.new
    t2 = TestNode.new

    # when
    [*TestNode.all].size.should == 2
    [*TestNode.all.nodes].should include(t1)
    [*TestNode.all.nodes].should include(t2)
  end

  it "should return wrapped Ruby object and not native Neo4j Java Nodes" do
    class TestNode
      include Neo4j::NodeMixin
    end

    t1 = TestNode.new

    # when
    x = [*TestNode.all.nodes][0]
    puts "X=#{x} inspect: #{x.props.inspect}"
    x.should be_kind_of(TestNode)
  end


  it "should create a referense from the reference node root" do
    class TestNode5
      include Neo4j::NodeMixin
    end

    index_node = Neo4j::IndexNode.instance
    index_node.rels.outgoing(TestNode5).should be_empty

    # when
    t = TestNode5.new

    # then
    nodes = index_node.rels.outgoing(TestNode5).nodes
    [*nodes].size.should == 1
    nodes.should include(t)
  end


  it "should create a referense from the reference node root for inherited classes" do
    class TestNode6
      include Neo4j::NodeMixin
    end

    class SubNode6 < TestNode6
    end

    index_node = Neo4j::IndexNode.instance
    index_node.rels.outgoing(TestNode6).should be_empty

    # when
    t = SubNode6.new

    # then
    nodes = index_node.rels.outgoing(TestNode6).nodes
    [*nodes].size.should == 1
    nodes.should include(t)
    SubNode6.root_class.should == TestNode6
  end

  it "should not return deleted node instances" do
    class TestNode
      include Neo4j::NodeMixin
    end

    t1 = TestNode.new
    t2 = TestNode.new
    [*TestNode.all].size.should == 2

    # when
    t1.del
    [*TestNode.all].size.should == 1
    [*TestNode.all.nodes].should include(t2)
  end

  it "should return subclasses instances if subclassed" do
    class A
      include Neo4j::NodeMixin
    end

    class B < A
    end

    # when
    a = A.new
    b = B.new

    # then
    [*A.all].size.should == 2
    [*A.all.nodes].should include(a, b)
    [*B.all].size.should == 1
    [*B.all.nodes].should include(b)
  end

end



describe "Reindex" do
  before(:all) do
    start
    require 'neo4j/extensions/reindexer'
    Neo4j.load_reindexer # since a previous test might have unloaded this extension
  end

  after(:all) do
    Neo4j.unload_reindexer # since a previous test might have unloaded this extension
    stop
  end

  it "should reindex nodes after the neo4j has restarted (lighthouse ticket #53)" do
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
    [*TestNode.all.nodes].should include(t1)
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
    [*TestNode.all.nodes].should include(t2)
    Neo4j::Transaction.finish
  end
end


