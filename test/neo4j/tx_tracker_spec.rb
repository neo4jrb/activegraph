$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'
require 'neo4j/extensions/tx_tracker'


class TxTestNode
  include Neo4j::NodeMixin
  property :myid


  def to_s
    "TxTestNode " + props.inspect
  end
end


describe "TxTracker (TxNodeList)" do
  it "should set property 'tx_finished' on the last TxNode that was commited" do
    stop
    Neo4j.load_tx_tracker
    Neo4j.start
    @tx_node_list = Neo4j::TxNodeList.instance

    Neo4j::Transaction.run do
      TxTestNode.new.myid = '1'
      TxTestNode.new.myid = '2'
      TxTestNode.new.myid = '3'
    end

    Neo4j::Transaction.run do
      first = @tx_node_list.tx_nodes.first
      first[:tx_finished].should == true

      second = @tx_node_list.tx_nodes.to_a[1]
      second[:tx_finished].should be_nil

      third = @tx_node_list.tx_nodes.to_a[2]
      third[:tx_finished].should be_nil
    end
    stop
  end

end

describe "TxTracker (TxNodeList)" do


  before(:all) do
    Neo4j.start
    Neo4j.load_tx_tracker
    Neo4j::Transaction.new
    @tx_node_list = Neo4j::TxNodeList.instance
  end

  before(:each) do
    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish
  end

  after(:all) do
    stop

    # it is only this this spec that tests the TxTracker extension - remove it
    Neo4j.event_handler.remove(Neo4j::TxNodeList)
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
#    a[:uuid].should ==   =~ /UUID:\d+/

    tx_node = @tx_node_list.tx_nodes.first
    tx_node[:uuid].should == a[:uuid]
    tx_node[:created].should == true
  end


  it "should set property 'property_changed' when a node property is changed" do
    a = TxTestNode.new
    a.myid = "hej"

    first = @tx_node_list.tx_nodes.first
    first[:property_changed].should == true
    first[:old_value].should == nil
    first[:new_value].should == "hej"
  end

  it "should set property 'old_value' and 'new_value' when a node property is changed" do
    a = TxTestNode.new
    a.myid = "hej1"
    a.myid = "hej2"

    first = @tx_node_list.tx_nodes.first
    first[:property_changed].should == true
    first[:old_value].should == "hej1"
    first[:new_value].should == "hej2"
  end

  it "should be possible to undo a transaction on property changed" do
    a = TxTestNode.new
    a.myid = "hej1"
    a.myid = "hej2"
    a.myid.should == "hej2"
    id = a.neo_node_id

    # when
    Neo4j.undo_tx

    # then
    node = Neo4j.load(id)
    node.myid.should == "hej1"
  end

  it "should be possible to undo a transaction on node created" do
    a = TxTestNode.new
    id = a.neo_node_id

    # when
    Neo4j.load(id).should_not be_nil
    Neo4j.undo_tx
    Neo4j::Transaction.finish

    Neo4j::Transaction.new
    # then
    Neo4j.load(id).should be_nil
  end


  it "should be possible to undo a transaction on node deleted" do
    a = TxTestNode.new
    id = a.neo_node_id
    Neo4j.load(id).should_not be_nil

    a.delete
    Neo4j::Transaction.finish

    Neo4j::Transaction.new
    Neo4j.load(id).should be_nil

    # when
    Neo4j.undo_tx

    Neo4j::Transaction.finish

    Neo4j::Transaction.new
    # then
    Neo4j.load(id).should be_nil
  end

end