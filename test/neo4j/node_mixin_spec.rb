$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'spec_helper'


# ----------------------------------------------------------------------------
# initialize
#

describe Neo4j::NodeMixin do
  before(:all) do
    delete_db
  end

  after(:all) do
    stop
  end

  describe '#initialize' do

    before(:each) do
      Neo4j::Transaction.new
    end

    after(:each) do
      Neo4j::Transaction.finish
    end

    it "should accept no arguments" do
      class TestNode1
        include Neo4j::NodeMixin
      end
      TestNode1.new
    end

    it "should allow to create a node from a native Neo Java object" do
      class TestNode4
        include Neo4j::NodeMixin
      end

      node1 = TestNode4.new
      node2 = TestNode4.new(node1._java_node)
      node1._java_node.should == node2._java_node
    end

    it "should take an hash argument to initialize its properties" do
      class TestNode6
        include Neo4j::NodeMixin
        property :foo
      end

      node1 = TestNode6.new :name => 'jimmy', :foo => 42
      node1.foo.should == 42
      node1[:name].should == 'jimmy'
    end

    it "should accept a block and pass self as parameter" do
      class TestNode5
        include Neo4j::NodeMixin
        property :foo
      end

      node1 = TestNode5.new {|n| n.foo = 'hi'}
      node1.foo.should == 'hi'
    end
  end


  describe '#init_node' do

    before(:each) do
      Neo4j::Transaction.new
    end

    after(:each) do
      Neo4j::Transaction.finish
    end

    it "should allow to initialize itself with one argument" do
      # given an initialize method
      class TestNode2
        include Neo4j::NodeMixin

        def init_node(arg1, arg2)
          self[:arg1] = arg1
          self[:arg2] = arg2
        end

      end

      # when
      n = TestNode2.new 'arg1', 'arg2'

      # then
      n[:arg1].should == 'arg1'
      n[:arg2].should == 'arg2'
    end


    it "should allow arguments for the initialize method" do
      class TestNode3
        include Neo4j::NodeMixin
        attr_reader :foo

        def init_node(value)
          @foo = value
          self[:name] = "Name #{value}"
        end
      end
      n = TestNode3.new 'hi'
      n.foo.should == 'hi'
      n[:name].should == "Name hi"
      id = n.neo_id
      p = Neo4j.load_node(id)
      p[:name].should == "Name hi"
      p.foo.should == nil
    end

    
  end

  describe '#equal' do
    class EqualNode
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

    it "should be == another node only if it has the same node id" do
      node1 = EqualNode.new
      node2 = Neo4j.load_node(node1.neo_id)
      node2.should be_equal(node1)
      node2.should == node1
      node2.hash.should == node1.hash
    end

    it "should not be == another node only if it has not the same node id" do
      node1 = EqualNode.new
      node2 = EqualNode.new
      node2.should_not be_equal(node1)
      node2.should_not == node1
      node2.hash.should_not == node1
    end

  end

end


class DelegateTest
  include Neo4j::NodeMixin
end

DELEGATE = %w<[]= [] property? props update neo_id rels rel rel?>
DELEGATE.each do |del|
  describe Neo4j::NodeMixin, "##{del}" do
    before(:each) do
      @mock = mock("java_node")
      @mock.should_receive(:kind_of?).and_return(true)
      @mock.should_receive(:_wrapper=).with(any_args())
      @node = DelegateTest.new(@mock)
    end

    it "should be forwarded to Neo4j::JavaPropertyMixin##{del}" do
      @mock.should_receive(del.to_sym)
      args = [del.to_sym] + (0..@node.method(del.to_sym).arity).to_a
      @node.send *args
    end
  end
end


#
#describe 'NodeMixin properties' do
#
#  before(:all) do
#    start
#  end
#
#  before(:each) do
#    Neo4j::Transaction.new
#  end
#
#  after(:each) do
#    Neo4j::Transaction.finish
#  end
#
#  it "should behave like a hash" do
#    n = Neo4j::Node.new
#    n[:a] = 'a'
#    n[:a].should == 'a'
#    n['foo'] = 42
#    n['foo'].should == 42
#    n[34] = true
#    n[34].should == true
#  end
#
#  it "should allow to update properties" do
#    n = Neo4j::Node.new
#    n[:a] = 'a'
#    n[:a] = 'b'
#    n[:a].should == 'b'
#  end
#end
#
#
#
## ----------------------------------------------------------------------------
## equality ==
##
#
#describe 'NodeMixin#equality (==)' do
#
#  before(:all) do
#    start
#
#    NODES = 5
#    @nodes = []
#    Neo4j::Transaction.run do
#      NODES.times { @nodes << Neo4j::Node.new}
#    end
#
#  end
#
#  before(:each) do
#    Neo4j::Transaction.new
#  end
#
#  after(:each) do
#    Neo4j::Transaction.finish
#  end
#
#  it "should be == another node only if it has the same node id" do
#    node = Neo4j::Node.new(@nodes[0]._java_node)
#    node._java_node.should be_equal(@nodes[0]._java_node)
#    node.should == @nodes[0]
#    node.hash.should == @nodes[0].hash
#  end
#
#  it "should not be == another node only if it has not the same node id" do
#    node = Neo4j::Node.new(@nodes[1]._java_node)
#    node._java_node.should_not be_equal(@nodes[0]._java_node)
#    node.should_not == @nodes[0]
#    node.hash.should_not == @nodes[0].hash
#  end
#
#end
#
#
#
