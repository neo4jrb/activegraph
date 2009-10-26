$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/extensions/aggregate'
require 'neo4j/spec_helper'


AggregateEachNode = Neo4j::Aggregate::AggregateEachNode

describe "Aggregate each node" do
  before(:all) do
    class Company
      include Neo4j::NodeMixin
      property :month, :revenue
    end
  end

  after(:all) do
    undefine_class :Company
  end

  before(:each) do
    start
    Neo4j::Transaction.new
    @registrations = []
  end

  after(:each) do
    stop
    @registrations.each {|reg| reg.unregister}
  end

  describe "Access aggregated node properties" do
    before(:each) do
#      Neo4j::Transaction.new
      @nodes = []
      4.times {@nodes << Neo4j::Node.new}
      @nodes[0][:colour] = 'red';  @nodes[0][:name] = "a";  @nodes[0][:age] = 0
      @nodes[1][:colour] = 'red';  @nodes[1][:name] = "b";  @nodes[1][:age] = 1
      @nodes[2][:colour] = 'red';  @nodes[2][:name] = "c";  @nodes[2][:age] = 2
      @nodes[3][:colour] = 'blue'; @nodes[3][:name] = "d";  @nodes[3][:age] = 3

      # when
      @aggregate_node = AggregateEachNode.new
      @aggregate_node.aggregate_each(@nodes).group_by(:colour, :name).execute
    end

    it "can be retrieved as a group Neo4j::NodeMixin#aggregate_groups" do
            Neo4j::Transaction.new
      # then we should have one group
      @nodes[0].aggregate_groups.to_a.size.should == 1
      group = @nodes[0].aggregate_groups.to_a[0]

      # and that group should contain the node property values
      group.should include('red', 'a')
      group.to_a.size.should == 2
      group[:age].should == 0 # group for @nodes[0]
    end

    it "can all be retrieved from the aggregate node" do
      # there are total 8 property values
      @aggregate_node.to_a.sort.should == ["blue", "d", "red", "c", "red", "b", "red", "a"].sort
    end

    it "can be retrieved from the aggregate node as an group" do
      # there are total 4 groups
      @aggregate_node.aggregate_size.should == 4

      # so that we know which group is which group we put it in a age_groups map
      age_groups = {}
      @aggregate_node.groups.each {|g| age_groups[g[:age]] = g}

      age_groups[3].should include('blue','d')
      age_groups[0].should include('red','a')
    end
  end

  it "should delete group if the node is deleted" do
    nodes = []
    4.times {nodes << Neo4j::Node.new}
    nodes[0][:colour] = 'red'; nodes[0][:name] = "a"; nodes[0][:age] = 0
    nodes[1][:colour] = 'red'; nodes[1][:name] = "b"; nodes[1][:age] = 1
    nodes[2][:colour] = 'red'; nodes[2][:name] = "c"; nodes[2][:age] = 2
    nodes[3][:colour] = 'blue'; nodes[3][:name] = "d"; nodes[3][:age] = 3

    agg1 = AggregateEachNode.new
    agg1.aggregate_each(nodes).group_by(:colour, :name)
    agg1.to_a.size.should == 8
    agg1.aggregate_size.should == 4
    agg1.groups.size.should == 4


    # when
    n = nodes[2].aggregate_groups.to_a[0]
    n.delete

    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    # then
    agg1.to_a.size.should == 6
    agg1.aggregate_size.should == 3
  end


  it "should create new groups for each node, group by quarter" do
    revenue1 = Neo4j::Node.new
    revenue2 = Neo4j::Node.new
    revenue1[:jan] = 1; revenue1[:feb] = 2; revenue1[:mars] = 3; revenue1[:april] = 4; revenue1[:may] = 5; revenue1[:june] = 6
    revenue2[:jan] = 11; revenue2[:feb] = 12; revenue2[:mars] = 13; revenue2[:april] = 14; revenue2[:may] = 15; revenue2[:june] = 16

    # when
    q1 = AggregateEachNode.new
    q1.aggregate_each([revenue1, revenue2]).group_by(:jan, :feb, :mars)

    q2 = AggregateEachNode.new
    q2.aggregate_each([revenue1, revenue2]).group_by(:april, :may, :june)

    # then there should be two groups, one for each revenue node
    q1.aggregate_size.should == 2
    # with each 3 values, total 6 (2*3)
    q1.to_a.sort.should == [1, 2, 3, 11, 12, 13]
    q2.to_a.sort.should == [4, 5, 6, 14, 15, 16]
  end


  it "should allow to find the aggregates a node belongs to based on a id" do
    q1 = AggregateEachNode.new(:q1)
    q2 = AggregateEachNode.new(:q2)

    # when
    c1 = Company.new
    c1[:jan] = 100
    c1[:feb] = 200
    c1[:mars] = 300
    c1[:april] = 400
    c1[:may] = 500
    c1[:june] = 600

    c2 = Company.new
    c2[:jan] = 1100
    c2[:feb] = 1200
    c2[:mars] = 1300
    c2[:april] = 1400
    c2[:may] = 1500
    c2[:june] = 1600

    q1.aggregate_each([c1, c2]).group_by(:jan, :feb, :mars).execute
    q2.aggregate_each([c1, c2]).group_by(:april, :may, :june).execute

    # then
    q1.groups.should include(c1.aggregate_groups(:q1))
    q1.groups.should include(c2.aggregate_groups(:q1))
    q2.groups.should include(c1.aggregate_groups(:q2))
    q2.groups.should include(c2.aggregate_groups(:q2))
  end

  it "should allow to register nodes classes to be part of aggregates" do
    # given
    q1 = AggregateEachNode.new(:q1)
    @registrations << q1.aggregate_each(Company).group_by(:jan, :feb, :mars)
    q2 = AggregateEachNode.new(:q2)
    @registrations << q2.aggregate_each(Company).group_by(:april, :may, :june)

    # when
    c1 = Company.new
    c1[:jan] = 100
    c1[:feb] = 200
    c1[:mars] = 300
    c1[:april] = 400
    c1[:may] = 500
    c1[:june] = 600

    c2 = Company.new
    c2[:jan] = 1100
    c2[:feb] = 1200
    c2[:mars] = 1300
    c2[:april] = 1400
    c2[:may] = 1500
    c2[:june] = 1600

    # then
    q1.should include(100, 200, 300, 1100, 1200, 1300)
    q2.should include(400, 500, 600, 1400, 1500, 1600)
  end

  it "should update the aggregate when a node changes" do
    q1 = AggregateEachNode.new(:q1)
    @registrations << q1.aggregate_each(Company).group_by(:jan, :feb, :mars)

    # given
    c1 = Company.new
    c1[:jan] = 100
    c1[:feb] = 200
    q1.should include(100, 200)

    # when
    c1[:feb] = 42

    # then
    q1.should_not include(200)
    q1.should include(42)
  end

  it "should delete the group when the node is deleted" do
    pending
    q1 = AggregateEachNode.new(:q1)
    @registrations << q1.aggregate_each(Company).group_by(:jan, :feb, :mars)

    # given
    c1 = Company.new
    c1[:jan] = 100
    c1[:feb] = 200
    q1.should include(100, 200)
    q1.groups.size.should == 1
    Neo4j.load(q1.neo_node_id).should_not be_nil

    # when
    c1.delete

    # then
    q1.groups.size.should == 0
    q1.should_not include(100)
    q1.should_not include(200)
  end

  it "should allow to register nodes classes to be part of aggregates" do
#    pending
    # given
    q1 = AggregateEachNode.new(:q1)
    q1.aggregate_each(Company).group_by(:jan, :feb, :mars).with(:sum){|sum, val, prev_val| sum + val - prev_val}
    q2 = AggregateEachNode.new(:q2)
    q2.aggregate_each(Company).group_by(:april, :may, :june).with(:sum){|sum, val, prev_val| sum + val - prev_val}

    # when
    c1 = Company.new
    c1[:jan] = 100
    c1[:feb] = 200
    c1[:mars] = 300
    c1[:april] = 400
    c1[:may] = 500
    c1[:june] = 600

    # then
    puts "C1 GROUP Q1: #{c1.aggregate_groups(:q1).neo_node_id}"
    puts "C1 GROUP Q2: #{c1.aggregate_groups(:q2).neo_node_id}"

    c1.aggregate_groups(:q1)[:sum].should == 100+200+300
    c1.aggregate_groups(:q2)[:sum].should == 400+500+600
  end
end