$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/extensions/aggregate'
require 'neo4j/spec_helper'


AggregateEachNode = Neo4j::Aggregate::AggregateEachNode

describe "Aggregates, on each node" do
  before(:each) do
    start
    Neo4j::Transaction.new
  end

  after(:each) do
    stop
  end

  it "should create a new group for each node" do
    #pending "work in progress"
    nodes = []
    4.times {nodes << Neo4j::Node.new}
    nodes[0][:colour] = 'red';  nodes[0][:name] = "a"; nodes[0][:age] = 0
    nodes[1][:colour] = 'red';  nodes[1][:name] = "b"; nodes[1][:age] = 1
    nodes[2][:colour] = 'red';  nodes[2][:name] = "c"; nodes[2][:age] = 2
    nodes[3][:colour] = 'blue'; nodes[3][:name] = "d"; nodes[3][:age] = 3


    agg1 = AggregateEachNode.new

    # when
    agg1.aggregate_each(nodes).group_by(:colour, :name).execute

    # then
    nodes[0].aggregate_groups.to_a.size.should == 1
    g1 = nodes[0].aggregate_groups.to_a[0]
    g1.should include('red', 'a')
    g1.to_a.size.should == 2
    g1[:age].should == 0 # group for @nodes[0]

    agg1.should include(g1)
    agg1.to_a.size.should == 4
    agg1.aggregate_size.should == 4
    sum = agg1.inject([]) {|s,g| g.inject(s) {|ss,n| ss << n}}
    
    agg1.map{|group| group[:age]}.should include(0,1,2,3)
  end

  it "should delete group if the node is deleted" do
#    pending "Need to fix lighthouse ticket 81 - Cascade delete on has_n, had_one and has_list first"

    nodes = []
    4.times {nodes << Neo4j::Node.new}
    nodes[0][:colour] = 'red';  nodes[0][:name] = "a"; nodes[0][:age] = 0
    nodes[1][:colour] = 'red';  nodes[1][:name] = "b"; nodes[1][:age] = 1
    nodes[2][:colour] = 'red';  nodes[2][:name] = "c"; nodes[2][:age] = 2
    nodes[3][:colour] = 'blue'; nodes[3][:name] = "d"; nodes[3][:age] = 3

    agg1 = AggregateEachNode.new
    agg1.aggregate_each(nodes).group_by(:colour, :name).execute # TODO should not be needed to do execute
    agg1.to_a.size.should == 4
    agg1.aggregate_size.should == 4

    # when
    #nodes[2].delete
    n = nodes[2].aggregate_groups.to_a[0]
    n.delete

    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    # then
    agg1.to_a.size.should == 3
    agg1.aggregate_size.should == 3
  end


  it "should create new groups for each node, group by quarter" do
    pending

    revenue1 = Neo4j::Node.new
    revenue2 = Neo4j::Node.new
    revenue1[:jan] = 1;  revenue1[:feb] = 2;  revenue1[:mars] = 3;  revenue1[:april] = 4;  revenue1[:may] = 5;  revenue1[:june] = 6
    revenue2[:jan] = 11; revenue2[:feb] = 12; revenue2[:mars] = 13; revenue2[:april] = 14; revenue2[:may] = 15; revenue2[:june] = 16

    # when
    q1 = AggregateNode.new
    q1.aggregate_each([revenue1, revenue2]).group_by(:jan, :feb, :mars)

    q2 = AggregateNode.new
    q2.aggregate_each([revenue1, revenue2]).group_by(:april, :may, :june)

    q1.to_a.size.should == 2 # there should be two groups, one for each revenue node
    g1 = q1.to_a[0]
    g1.should include(1,2,3)
    g2 = q2.to_a[0]
    g2.should include(11,12,13)
  end

  it "should create groups of groups" do
    pending

    q1 = AggregateNode.new
    q2 = AggregateNode.new

    quarters = AggregateNode.new
    quarters.add_group(:q1, q1)
    quarters.add_group(:q2, q2)

    # then
    quarters[:q1].should == q1
    quarters[:q2].should == q2
  end
end