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


  before(:each) do
    start
    Neo4j.load_tx_tracker
    @tx_node_list = Neo4j::TxNodeList.instance
  end

  after(:each) do
    stop
  end


  it "should have a reference to the TxNodeList" do
    @tx_node_list.should_not be_nil
  end

  it "should be empty TxNode when first started" do
    @tx_node_list.tx_nodes.empty?.should be_true
  end

  it "should not be empty TxNode when a node has been created" do
    @tx_node_list.tx_nodes.empty?.should be_true

    Neo4j::Transaction.run { TxTestNode.new }
    @tx_node_list.tx_nodes.empty?.should be_false
  end

  it "should set a UUID on the node and the TxNode and property created=true" do
    a = Neo4j::Transaction.run {  TxTestNode.new }

    tx_node = @tx_node_list.tx_nodes.first
    tx_node[:uuid].should == a[:uuid]
    tx_node[:created].should == true
  end


  it "should set property 'property_changed' when a node property is changed" do
    a =  Neo4j::Transaction.run { TxTestNode.new }
    Neo4j::Transaction.run { a.myid = "hej" }

    first = @tx_node_list.tx_nodes.first
    first[:property_changed].should == true
    first[:old_value].should == nil
    first[:new_value].should == "hej"
  end

  it "should set property 'old_value' and 'new_value' when a node property is changed" do
    Neo4j::Transaction.run do
      a = TxTestNode.new
      a.myid = "hej1"
      a.myid = "hej2"
    end

    first = @tx_node_list.tx_nodes.first
    first[:property_changed].should == true
    first[:old_value].should == "hej1"
    first[:new_value].should == "hej2"
  end

  it "should be possible to undo a transaction on property changed" do
    a = Neo4j::Transaction.run { TxTestNode.new }
    Neo4j::Transaction.run { a.myid = "hej1" }
    Neo4j::Transaction.run do
      a.myid = "hej2"
      a.myid.should == "hej2"
    end
    id = a.neo_node_id

    # when
    Neo4j::Transaction.run { Neo4j.undo_tx }

    # then
    node = Neo4j.load(id)
    node.myid.should == "hej1"
  end

  it "should be possible to undo a transaction on node created" do
    Neo4j::Transaction.new

    a = TxTestNode.new
    id = a.neo_node_id
    Neo4j::Transaction.finish

    Neo4j::Transaction.new
    
    # when
    Neo4j.load(id.to_i).should_not be_nil # make sure it exists
    Neo4j.undo_tx

    # then
    Neo4j::Transaction.finish

    # make sure it has been deleted
    Neo4j::Transaction.run { Neo4j.load(id).should == nil }
  end


  it "should undo create and delete of a node when Neo4j.undo_tx" do
    # given, create and delete a node in the same transaction
    Neo4j::Transaction.new
    a = TxTestNode.new
    id = a.neo_node_id
    a.delete
    Neo4j::Transaction.finish

    # when deleted
    Neo4j::Transaction.new
    Neo4j.load(id).should be_nil # make sure it is deleted
    Neo4j.undo_tx
    Neo4j::Transaction.finish

    # then
    Neo4j::Transaction.new
    Neo4j.load(id).should be_nil
    Neo4j::Transaction.finish
  end

  it "should undo delete node when Neo4j.undo_tx" do
    # given, create a node
    Neo4j::Transaction.new
    a = TxTestNode.new
    id = a.neo_node_id
    Neo4j::Transaction.finish

    # next transaction - delete it
    Neo4j::Transaction.new
    a.delete
    Neo4j::Transaction.finish

    # when deleted
    Neo4j::Transaction.new
    Neo4j.load(id).should be_nil # make sure it is deleted
    Neo4j.undo_tx
    Neo4j::Transaction.finish

    # then
    Neo4j::Transaction.new
    Neo4j.load(id).should be_nil
    Neo4j::Transaction.finish
  end


  it "should set property 'tx_finished' on the last TxNode that was commited" do
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
  end


  it "should undo setting properties" do
    @tx_node_list = Neo4j::TxNodeList.instance

    node1 = node2 = node3 = nil

    # Transaction 1
    Neo4j::Transaction.run do
      node1 = TxTestNode.new
      node1.myid = '1'
      node2 = TxTestNode.new
      node2.myid = '2'
    end


    # Transaction 2
    Neo4j::Transaction.run do
      node2.myid = 'x'
      node3 = TxTestNode.new
      node3.myid = '3'
    end


    # when undo transaction 2
    Neo4j::Transaction.run { Neo4j.undo_tx }


    # then
    Neo4j::Transaction.run do
      Neo4j.load(node3.neo_node_id).should be_nil
      node2.myid.should == '2'
    end
  end

  it "should undo a new relationship" do
    a = Neo4j::Transaction.run { Neo4j::Node.new}
    b = Neo4j::Transaction.run { Neo4j::Node.new}
    rel = Neo4j::Transaction.run { a.relationships.outgoing(:foobar) << b}
    rel_id = rel.neo_relationship_id
    Neo4j::Transaction.run { Neo4j.load_relationship(rel_id).should == rel }

    # when
    Neo4j::Transaction.run { Neo4j.undo_tx }

    # then
    Neo4j::Transaction.run { Neo4j.load_relationship(rel_id).should == nil }
  end

  it "should undo delation of relationship" do
    a = Neo4j::Transaction.run { Neo4j::Node.new}
    b = Neo4j::Transaction.run { Neo4j::Node.new}
    rel = Neo4j::Transaction.run { a.relationships.outgoing(:foobar) << b}
    # make sure relationship exists
    Neo4j::Transaction.run { a.relationship?(:foobar).should be_true }

    # delete relationship
    Neo4j::Transaction.run { rel.delete }

    # make sure it is deleted
    Neo4j::Transaction.run { a.relationship?(:foobar).should be_false }

    # when
    Neo4j::Transaction.run { Neo4j.undo_tx }


    # then
    # make sure relationship exists
    Neo4j::Transaction.run { a.relationship?(:foobar).should be_true }
  end

end