$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'



# ----------------------------------------------------------------------------
# initialize
#

describe 'NodeMixin#initialize' do

  before(:all) do
    start
  end

  before(:each) do
    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish
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
      property :baaz

      def initialize(baaz)
        super
        @foo = "bar"
        self.baaz = baaz
      end

    end

    # when
    n = TestNode2.new('hajhaj')

    # then
    n.foo.should == 'bar'
    n[:baaz].should == 'hajhaj'
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

  before(:all) do
    start
  end

  before(:each) do
    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish
  end

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

    start
  end

  before(:each) do
    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish
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
    t['oj'].should == 'hoj'
  end

  it "should be able to update a node by using a hash" do
    t = TestNode.new
    t.update({:name=>'andreas', :age=>3})
    t.name.should == 'andreas'
    t.age.should == 3
  end

  it "should not allow the classname to be changed" do
    t = TestNode.new
    t.update({:classname => 'wrong'})
    t.classname.should == 'TestNode'
  end

  it "should not allow the id to be changed" do
    t = TestNode.new
    t.update({:id => 987654321})
    t.props['id'].should == t.neo_node_id
  end

  it "should remove attributes that are not mentioned if the strict option is set" do
    t = TestNode.new
    t.update({:name=>'andreas', :age=>3})
    t.update({:age=>4}, :strict => true)
    t.name.should be_nil
  end

  it "should not remove attributes that are not mentioned if the strict option is not set" do
    t = TestNode.new
    t.update({:name=>'andreas', :age=>3})
    t.update({:age=>4})
    t.name.should == 'andreas'
  end
end


# ----------------------------------------------------------------------------
# equality ==
#

describe 'NodeMixin#equality (==)' do

  before(:all) do
    start
    
    NODES = 5
    @nodes = []
    Neo4j::Transaction.run do
      NODES.times { @nodes << Neo4j::Node.new}
    end
    
  end

  before(:each) do
    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish
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
  before(:all) do
    start
  end

  before(:each) do
    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish
  end

  it "should remove the node from the database after the transaction finish" do
    # given
    node = Neo4j::Node.new
    id = node.neo_node_id
    
    # when
    node.delete
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    
    # then
    Neo4j.load(id).should == nil
  end


  it "should not remove the node from the database if the transaction has not finish" do
    # given
    node = Neo4j::Node.new
    id = node.neo_node_id

    # when
    node.delete

    # then
    Neo4j.load(id).should_not be_nil
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

# ----------------------------------------------------------------------------
# props
#

describe "Neo4j::Node#props"  do
  before(:all) do
    start
    undefine_class :TestNode
    class TestNode
      include Neo4j::NodeMixin

      property :name
      property :age
    end
  end

  after(:all) do
    stop
  end
  
  before(:each) do
    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish
  end
  

  before(:each) do
    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish    
  end

  it "should only contain id and classname on a node with no properties" do
    t1 = TestNode.new
    p = t1.props
    p.keys.should include('id')
    p.keys.should include('classname')
    p['id'].should == t1.neo_node_id
    p['classname'].should == 'TestNode'
    p.keys.size.should == 2
  end

  it "should be okay to call props on a loaded node with no properties" do
    t1 = TestNode.new
    id = t1.neo_node_id
    t2 = Neo4j.load(id)
    p = t2.props
    p.keys.should include('id')
    p.keys.should include('classname')
    p.keys.size.should == 2
  end

  it "should return declared properties" do
    t1 = TestNode.new
    t1.name = 'abc'
    t1.age = 3
    p = t1.props
    p['name'].should == 'abc'
    p['age'].should == 3
  end

  it "should return undeclared properties" do
    t1 = TestNode.new
    t1.set_property('hoj', 'koj')
    p = t1.props
    p.keys.should include('hoj')
    p['hoj'].should == 'koj'
  end

end

