$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'



# ------------------------------------------------------------------------------
# Neo
# 

#$NEO_LOGGER.level = Logger::DEBUG

describe "Neo4j" do
  it "should not need to be started or stopped before using it" do
    undefine_class :Foo
    class Foo
      include Neo4j::NodeMixin
      property :name
      index :name
    end
    res = Foo.find(:name => 'kalle')
    res.size.should == 0
    f = Foo.new
    f.name = 'kalle'
    res = Foo.find(:name => 'kalle')
    res.size.should == 1
    res[0].name.should == 'kalle'
  end
end

describe Neo4j::Neo do
  before(:each) do
    start
  end

  after(:each) do
    stop
  end
  
  it "should return a new neo instance if neo has been stopped" do
    x = Neo4j.instance
    Neo4j.stop
    Neo4j.instance.should_not == x
  end
 
  it "should have a reference node" do
    ref_node = Neo4j.instance.ref_node
    ref_node.should_not be_nil
  end

  it "should find a node given its neo node id" do
    # given
    class TestNode
      include Neo4j::NodeMixin
    end
    t1 = TestNode.new

    # when
    t2 = Neo4j.instance.find_node(t1.neo_node_id)

    # then
    t1.should == t2
  end

  it "should not find a node that does not exist" do
    n = Neo4j.instance.find_node(10)
    n.should be_nil
  end
  
end
