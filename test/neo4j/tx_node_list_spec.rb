$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'
require 'neo4j/tx_node_list'


class TxTestNode
  include Neo4j::NodeMixin
end

describe "TxNodeList" do


  before(:all) do  
    Neo4j::Config[:track_tx] = true
  end

  before(:each) do
    stop
    start
    @tx_node_list = Neo4j::TxNodeList.instance
  end

  after(:all) do
    stop
    Neo4j::Config[:track_tx] = false  
  end

  it "should have a reference to the TxNodeList" do
    @tx_node_list.should_not be_nil
  end

  it "should be empty TxNode when first started" do
    @tx_node_list.tx_nodes.empty?.should be_true
  end

  it "should not be empty TxNode when a node has been created" do
    @tx_node_list.tx_nodes.empty?.should be_true

    a = TxTestNode.new
    @tx_node_list.tx_nodes.empty?.should be_false
  end

  it "should set a UUID on the node and the TxNode and property created=true" do
    a = TxTestNode.new
    a[:uuid].should =~ /UUID:\d+/

    tx_node = @tx_node_list.tx_nodes.first
    tx_node[:uuid].should == a[:uuid]
    tx_node[:created].should == true
  end


end