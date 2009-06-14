$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'



# ----------------------------------------------------------------------------
# initialize
#

describe 'NodeMixin#initialize' do
  before(:each)  do
    stop
    undefine_class :TestNode, :SubNode  # must undefine this since each spec defines it
    start
  end

  it "should accept no arguments"  do
    class TestNode1
      include Neo4j::NodeMixin
    end
    TestNode1.new
  end

  it "should allow to initialize itself"  do
    # given an initialize method
    class TestNode2
      include Neo4j::NodeMixin
      attr_reader :foo

      def initialize
        @foo = "bar"
      end
    end

    # when
    n = TestNode2.new

    # then
    n.foo.should == 'bar'
  end


  it "should allow arguments for the initialize method"  do
    class TestNode3
      include Neo4j::NodeMixin
      attr_reader :foo

      def initialize(value)
        @foo = value
      end
    end
    n = TestNode3.new 'hi'
    n.foo.should == 'hi'
  end

  it "should allow to create a node from a native Neo Java object" do
    class TestNode4
      include Neo4j::NodeMixin
    end

    node1 = TestNode4.new
    node2 = TestNode4.new(node1.internal_node)
    node1.internal_node.should == node2.internal_node
  end

end


describe 'NodeMixin properties' do

  it "should behave like a hash" do
    n = Neo4j::Node.new
    n[:a] = 'a'
    n[:a].should == 'a'
    n['foo'] = 42
    n['foo'].should == 42
    n[34] = true
    n[34].should == true
  end

  it "should allow to update properties" do
    n = Neo4j::Node.new
    n[:a] = 'a'
    n[:a] = 'b'
    n[:a].should == 'b'
  end
end

# ----------------------------------------------------------------------------
# update
#

describe 'NodeMixin#update' do

  before(:all) do
    class TestNode
      include Neo4j::NodeMixin
      property :name, :age
    end
  end

  after(:all) do
    stop
  end
  
  it "should be able to update a node from a value obejct" do
    # given
    t = TestNode.new
    t[:name]='kalle'
    t[:age]=2
    vo = t.value_object
    t2 = TestNode.new
    t2[:name] = 'foo'

    # when
    t2.update(vo)

    # then
    t2[:name].should == 'kalle'
    t2[:age].should == 2
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

describe 'NodeMixin#equality (==)' do

  after(:all) do
    stop
  end
  
  before(:all) do
    NODES = 5
    @nodes = []
    NODES.times {@nodes << Neo4j::Node.new}
  end

  it "should be == another node only if it has the same node id" do
    node = Neo4j::Node.new(@nodes[0].internal_node)
    node.internal_node.should be_equal(@nodes[0].internal_node)
    node.should == @nodes[0]
    node.hash.should == @nodes[0].hash
  end

  it "should not be == another node only if it has not the same node id" do
    node = Neo4j::Node.new(@nodes[1].internal_node)
    node.internal_node.should_not be_equal(@nodes[0].internal_node)
    node.should_not == @nodes[0]
    node.hash.should_not == @nodes[0].hash
  end

end



# ----------------------------------------------------------------------------
# delete
#

describe "Neo4j::Node#delete"  do
  after(:all) do
    stop
  end
  it "should delete all relationships as well" do
    # given
    t1 = Neo4j::Node.new
    t2 = Neo4j::Node.new
    t2.relationships.outgoing(:friends) << t1
    t2.relationships.both(:friends).nodes.to_a.should include(t1)

    # when
    t1.delete

    # then
    t2.relationships.both(:friends).nodes.to_a.should_not include(t1)
  end
end



