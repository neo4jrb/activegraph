$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../..")


require 'neo4j'
require 'neo4j/extensions/aggregate'
require 'spec_helper'

NodeAggregate = Neo4j::Aggregate::NodeAggregate

describe Neo4j::NodeMixin do

  before(:each) do
    start
    Neo4j::Transaction.new
  end

  after(:each) do
    stop
  end

  describe "#aggregates" do
    it "returns an empty enumerable when nodes does not belong to any aggregates" do
      node = Neo4j::Node.new
      node.aggregates.should be_empty
    end

    it "returns one aggregate node when it only belongs to one" do
      node = Neo4j::Node.new
      node[:colour] = 'green'

      agg_node = NodeAggregate.new
      agg_node.aggregate([node]).group_by(:colour).execute

      node.aggregates.first.should == agg_node
      [*node.aggregates].size.should == 1
    end

    it "returns two aggregates when one nodes belongs to two aggregates" do
      node = Neo4j::Node.new
      node[:colour] = 'green'

      agg_node1 = NodeAggregate.new
      agg_node1.aggregate([node]).group_by(:colour).execute

      agg_node2 = NodeAggregate.new
      agg_node2.aggregate([node]).group_by(:colour).execute

      node.aggregates.should include(agg_node1, agg_node2)
      [*node.aggregates].size.should == 2
    end

  end

  describe "#aggregate_groups" do
    it "should return an empty enumerable when node does not belong to a group" do
      node = Neo4j::Node.new
      node.aggregate_groups.should be_empty
    end

    it "should return one group when nodes belongs to one" do
      node = Neo4j::Node.new
      node[:colour] = 'green'
      agg_node = NodeAggregate.new

      agg_node.aggregate([node]).group_by(:colour).execute

      [*node.aggregate_groups].size.should == 1
      node.aggregate_groups.first.should be_kind_of(Neo4j::Aggregate::NodeGroup)
    end

    it "should return two groups when nodes belongs to two" do
      node = Neo4j::Node.new
      node[:colour] = 'green'
      node[:name] = 'andreas'
      agg_node = NodeAggregate.new

      agg_node.aggregate([node]).group_by(:colour, :name).execute

      [*node.aggregate_groups].size.should == 2
      [*node.aggregate_groups][0].should be_kind_of(Neo4j::Aggregate::NodeGroup)
      [*node.aggregate_groups][1].should be_kind_of(Neo4j::Aggregate::NodeGroup)      
    end

    it "should return the given group if found" do
      node = Neo4j::Node.new
      node[:colour] = 'green'
      agg_node = NodeAggregate.new

      agg_node.aggregate([node]).group_by(:colour).execute

      node.aggregate_groups('green').should be_kind_of(Neo4j::Aggregate::NodeGroup)
    end

    it "should return nil if given a group name that is not found" do
      node = Neo4j::Node.new
      node[:colour] = 'green'
      agg_node = NodeAggregate.new

      agg_node.aggregate([node]).group_by(:colour).execute

      node.aggregate_groups('black').should be_nil
    end

  end

end
