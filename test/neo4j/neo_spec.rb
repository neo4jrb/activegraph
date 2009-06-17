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
    Neo4j::Transaction.run do
      f = Foo.new
      f.name = 'kalle'
    end

    Neo4j::Transaction.run do
      res = Foo.find(:name => 'kalle')
      res.size.should == 1
      res[0].name.should == 'kalle'
    end
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
    Neo4j::Transaction.run do
      t1 = TestNode.new

      # when
      t2 = Neo4j.instance.find_node(t1.neo_node_id)

      # then
      t1.should == t2
    end

  end

  it "should not find a node that does not exist" do
    Neo4j::Transaction.run do
      n = Neo4j.instance.find_node(10)
      n.should be_nil
    end
  end


  it "should find a given relationship by id" do
    Neo4j::Transaction.run do
      n1 = Neo4j::Node.new
      n2 = Neo4j::Node.new
      rel = n1.relationships.outgoing(:foo) << n2

      r = Neo4j.load_relationship(rel.neo_relationship_id)

      rel.should == r
    end
  end


  it "should not find a given relationship by id that does not exist" do
    Neo4j::Transaction.run do
      n = Neo4j.load_relationship(101241)
      n.should be_nil
    end
  end

end
