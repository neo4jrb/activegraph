require 'neo4j'
require 'neo4j/spec_helper'



# ------------------------------------------------------------------------------
# Neo
# 

#$NEO_LOGGER.level = Logger::DEBUG

describe Neo4j::Neo do
  before(:all) do
    delete_db
  end

  after(:each) do
    Neo4j.stop # just to make sure it is stopped
  end
  
  it "should not be possible to get an instance if neo is stopped" do
    Neo4j.start NEO_STORAGE, LUCENE_INDEX_LOCATION
    Neo4j.stop
    Neo4j.instance.should be_nil
  end
 
  it "should have a reference node" do
    Neo4j.start NEO_STORAGE, LUCENE_INDEX_LOCATION
    ref_node = Neo4j.instance.ref_node
    ref_node.should_not be_nil
  end

  it "should find a node given its neo node id" do
    Neo4j.start NEO_STORAGE, LUCENE_INDEX_LOCATION

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
    Neo4j.start NEO_STORAGE, LUCENE_INDEX_LOCATION
    n = Neo4j.instance.find_node(10)
    n.should be_nil
  end
  
end
