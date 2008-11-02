require 'neo4j'
require 'neo4j/spec_helper'


# specs for Neo4j::Neo


# ------------------------------------------------------------------------------
# the following specs are run inside one Neo4j transaction
# 

describe "When running in one transaction" do
  before(:all) do
    start
  end

  after(:all) do
    stop
  end  
  
  before(:each) do
    @transaction = Neo4j::Transaction.new 
    @transaction.start
  end
  
  after(:each) do
    @transaction.failure # do& not want to store anything
    @transaction.finish
  end
  
  
  # ------------------------------------------------------------------------------
  # Neo
  # 

  describe Neo4j::Neo do

    it "should have a reference node" do
      ref_node = Neo4j::Neo.instance.ref_node
      ref_node.should_not be_nil
      ref_node.value = 'kalle'

      ref_node.value.should == 'kalle'
    end

    it "should find a node given its neo node id" do
      # given
      class TestNode 
        include Neo4j::NodeMixin
      end
      t1 = TestNode.new
      
      # when
      t2 = Neo4j::Neo.instance.find_node(t1.neo_node_id)
      
      # then
      t1.should == t2
    end
  
    it "should not find a node that does not exist" do
      #pending 'Neo trunk does not throw the correct exception, wait till they fix it '
      n = Neo4j::Neo.instance.find_node(10)
      n.should be_nil
    end
  
  end
end  
