$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'


class MyAggregateNode
  include Neo4j::NodeMixin
  include Neo4j::AggregateNodeMixin
end

describe "Aggregated nodes grouped by one property (colour)" do
  before(:all) do
    start
    Neo4j::Transaction.new
    @red=[]
    @blue=[]
    @green=[]
    5.times {@red << Neo4j::Node.new}
    4.times {@blue << Neo4j::Node.new}
    3.times {@green << Neo4j::Node.new}
    @red.each {|n| n[:colour] = 'red'}
    @blue.each {|n| n[:colour] = 'blue'}
    @green.each {|n| n[:colour] = 'green'}
    @all = @red + @blue + @green
    # create names a,b,c,d,a,b.c,d,a,b,c,d, ....
    names = []
    4.times { names += ('a' .. 'd').to_a}
    @all.each {|n| n[:name] = names.pop}
  end

  after(:all) do
    stop
  end

  # Called before each example.
  before(:each) do
    # For all nodes that have the same colour create a new aggregate node with property 'colour'
    # The ColourAggregateNode has outgoing relationship of type blue, black, red to those aggegated nodes.
    # Each aggregated node has a property colour with the value of its related nodes. There will be three aggregated nodes with property blue, black and red.
    # Those nodes are connected to all nodes that have this property with the same relationship.
    #
    #     @blue nodes<*----[aggregated node, prop colour='blue']<----<rel type=blue>--[@aggnode] ----<rel type=black>-->[aggregated node, prop colour='black']--->@black nodes
    #                                                                                      | <rel type=red>
    #                                                                                      V
    #                                                                                <relation: red>--->...
    @agg_node = MyAggregateNode.new
    @agg_node.aggregate(@all).group_by(:colour).execute
  end

  it "should have an enumeration of all groups" do
    @agg_node.to_a.size.should == 3
  end
  it "should have group nodes with propertie aggregate_group" do
    colours = @agg_node.inject([]) {|array, node| array << node.aggregate_group}
    colours.should include('red', 'blue', 'green')
  end

  it "should have size property for how many groups there are" do
    @agg_node.aggregate_size.should == 3
  end

  it "should have size property for each group" do
    @agg_node[:red].aggregate_size.should == 5
    @agg_node[:blue].aggregate_size.should == 4
    @agg_node[:green].aggregate_size.should == 3
  end

  it "should aggregate properties on aggregated nodes, e.g find name of all people having favorite colour 'red'" do
    names = @agg_node[:red][:name].to_a
    names.size.should == 5 # duplicated name 'd'
    names.should include('a', 'b', 'c', 'd')
  end

  it "should not add nodes to the aggreation that does not have a group property" do
    # add a node that does not have the colour property

    @agg_node.to_a.size.should == 3
    @agg_node[:red].aggregate_size.should == 5
    @agg_node[:blue].aggregate_size.should == 4
    @agg_node[:green].aggregate_size.should == 3

    @agg_node << Neo4j::Node.new

    @agg_node.to_a.size.should == 3
    @agg_node[:red].aggregate_size.should == 5
    @agg_node[:blue].aggregate_size.should == 4
    @agg_node[:green].aggregate_size.should == 3
  end
end


describe "Aggregate nodes grouped by one each property" do
  before(:all) do
    start
    Neo4j::Transaction.new
  end

  after(:all) do
    stop
  end

  it "should implement group_by_each" do
    node1 = Neo4j::Node.new; node1[:colour] = 'red'; node1[:type] = 'A'
    node2 = Neo4j::Node.new; node2[:colour] = 'red'; node2[:type] = 'B'

    agg_node = MyAggregateNode.new
    agg_node.aggregate([node1, node2]).group_by_each(:colour, :type).execute

    agg_node['red'].aggregate_size.should == 2
    agg_node['A'].aggregate_size.should == 1
    agg_node['A'].aggregate_size.should == 1

    agg_node['A'].should include(node1)
    agg_node['B'].should include(node2)
    agg_node['red'].should include(node1, node2)

    node1.aggregate_groups.to_a.size.should == 2
    node2.aggregate_groups.to_a.size.should == 2
  end
end

describe "Aggregate people into age groups 0-4, 5-9, 10-14" do
  before(:all) do
    start
    Neo4j::Transaction.run do
      @people = []
      6.times {@people << Neo4j::Node.new}
      @people[0][:age] = 2
      @people[1][:age] = 4
      @people[2][:age] = 5
      @people[3][:age] = 5
      @people[4][:age] = 9
      @people[5][:age] = 10
      # group 0 (0-4) - two people
      # group 1 (5-9) - three people
      # group 2 (10-14) - one person

      Neo4j::Transaction.new
      @aggregate_node = MyAggregateNode.new
      @aggregate_node.aggregate(@people).group_by(:age).map_value{|age| age / 5}.execute
    end
  end

  after(:all) do
    stop
  end

  it "should traverse all people in an age group" do
    @aggregate_node[0].should include(@people[0], @people[1])
    @aggregate_node[0].to_a.size.should == 2
    @aggregate_node[2].to_a.size.should == 1
    @aggregate_node[2].should include(@people[5])
  end


  it "should count number of people in each age group" do
    @aggregate_node.aggregate_size.should == 3 # there are 3 groups, 0-4, 5-9, 10-14
    @aggregate_node[0].aggregate_size.should == 2
    @aggregate_node[1].aggregate_size.should == 3
    @aggregate_node[2].aggregate_size.should == 1
  end

end


describe "Aggregate x and y coordinates into squares" do
  before(:all) do
    start
    Neo4j::Transaction.run do

      # create positions (0,0), (1,2), (2,4), (3,6) ...
      @positions = []
      6.times {@positions << Neo4j::Node.new}
      @positions.each_with_index {|p, index| p[:x] = index}
      @positions.each_with_index {|p, index| p[:y] = index*2}
      Neo4j::Transaction.new
      @aggregate_node = MyAggregateNode.new
      @aggregate_node.aggregate(@positions).group_by(:x, :y).map_value{|x, y| (x/3)*3+(y/3)}.execute
    end
  end

  after(:all) do
    stop
  end

  it "should traverse all positions in a square" do
    # find all coordinates in the square 0 - |0,0 2,0|
    #                                        |0,2 2,2|
    @aggregate_node[0].should include(@positions[0], @positions[1])
    @aggregate_node[0].aggregate_size.should == 2

    # find all coordinates in the square 1 - |0,3 2,3|
    #                                        |0,5 2,5|
    @aggregate_node[1].should include(@positions[2])
    @aggregate_node[1].aggregate_size.should == 1
  end

end


describe "Aggregate, append nodes" do
  before(:all) do
    start

    Neo4j::Transaction.new
    @red=[]
    @blue=[]
    @green=[]
    5.times {@red << Neo4j::Node.new}
    4.times {@blue << Neo4j::Node.new}
    3.times {@green << Neo4j::Node.new}
    @red.each {|n| n[:colour] = 'red'}
    @blue.each {|n| n[:colour] = 'blue'}
    @green.each {|n| n[:colour] = 'green'}
    @all = @red + @blue + @green

    # aggregate all nodes into colour groups
  end

  after(:all) do
    stop
  end

  it "should add node into existing groups using the << operator" do
    agg_node = MyAggregateNode.new
    agg_node.aggregate(@all).group_by(:colour).execute

    new_node = Neo4j::Node.new
    new_node[:colour] = 'green'
    agg_node[:green].aggregate_size.should == 3

    # when
    agg_node << new_node

    # then
    agg_node[:green].aggregate_size.should == 4
    agg_node[:green].should include(new_node)
  end

  it "should add node into new groups using the << operator" do
    agg_node = MyAggregateNode.new
    agg_node.aggregate(@all).group_by(:colour).execute

    new_node = Neo4j::Node.new
    new_node[:colour] = 'black'
    agg_node[:black].should be_nil

    # when
    agg_node << new_node

    # then
    agg_node[:black].aggregate_size.should == 1
    agg_node[:black].should include(new_node)
  end

  it "should allow to add node into an empty aggregation using << operator" do
    agg_node = MyAggregateNode.new
    agg_node.aggregate.group_by(:colour)

    new_node = Neo4j::Node.new
    new_node[:colour] = 'black'
    agg_node[:black].should be_nil

    # when
    agg_node << new_node

    # then
    agg_node[:black].aggregate_size.should == 1
    agg_node[:black].should include(new_node)
  end

  it "should implement an effecient include_node? method, by only searching in the relevant group" do
    agg_node = MyAggregateNode.new
    agg_node.aggregate.group_by(:colour)

    new_node = Neo4j::Node.new
    new_node[:colour] = 'black'

    agg_node.include_node?(new_node).should be_false
    agg_node << new_node

    # when
    agg_node.include_node?(new_node).should be_true
  end

  it "should not append a node to an aggregate if it already exist in the aggregate" do
    pending "Not sure if we want that. Will get bad performance if we have to check it each time we add a node to a aggregate"
    agg_node = MyAggregateNode.new
    agg_node.aggregate.group_by(:colour)

    new_node = Neo4j::Node.new
    new_node[:colour] = 'black'

    # when
    agg_node << new_node
    agg_node << new_node

    # then
    agg_node[:black].aggregate_size.should == 1
    agg_node[:black].should include(new_node)
  end
end

describe "Aggregates, over another aggregate" do
  before(:all) do
    start

    Neo4j::Transaction.new
    @set1 = [Neo4j::Node.new, Neo4j::Node.new]
    @set2 = [Neo4j::Node.new, Neo4j::Node.new]
    @set1[0][:colour] = 'red'
    @set1[1][:colour] = 'blue'

    @set2[0][:colour] = 'red';  @set2[0][:age] = 1
    @set2[1][:colour] = 'blue'; @set2[1][:age] = 2
  end

  after(:all) do
    stop
  end

  it "should add node into existing groups using the << operator" do
    agg1 = MyAggregateNode.new
    agg2 = MyAggregateNode.new

    agg1.aggregate(@set1).group_by(:colour).execute
    agg2.aggregate(@set2).group_by(:age).execute

    # when
    agg1 << agg2

    # then
    agg1[:red].aggregate_size.should == 2
    agg1[:red].should include(@set1[0], @set2[0])

    agg1[:blue].aggregate_size.should == 2
    agg1[:blue].should include(@set1[1], @set2[1])

    @set2[0].relationships.incoming.nodes.each {|x| puts "OUTGOING #{x.props.inspect}"}
  end

end


describe "Aggregates, each node should know which aggregate(s) it belongs to" do
  before(:each) do
    start

    Neo4j::Transaction.new
    @set1 = [Neo4j::Node.new, Neo4j::Node.new]
    @set2 = [Neo4j::Node.new, Neo4j::Node.new]
    @set1[0][:colour] = 'red'
    @set1[1][:colour] = 'blue'

    @set2[0][:colour] = 'red';  @set2[0][:age] = 1 # belongs to two aggregates
    @set2[1][:colour] = 'blue'; @set2[1][:age] = 2
  end

  after(:each) do
    stop
  end

  it "should know which aggregate it belongs to"  do
    agg1 = MyAggregateNode.new
    agg2 = MyAggregateNode.new
    agg1.aggregate(@set1).group_by(:colour).execute
    agg2.aggregate(@set2).group_by(:age).execute

    @set2[0].aggregates.to_a.size.should == 1

    agg1 << agg2
    
    @set2[0].aggregates.to_a.size.should == 2
    @set2[0].aggregates.to_a.should include(agg1, agg2)
  end

  it "should know which aggregate group it belongs to" do
    agg1 = MyAggregateNode.new
    agg2 = MyAggregateNode.new
    agg1.aggregate(@set1).group_by(:colour).execute
    agg2.aggregate(@set2).group_by(:age).execute

    @set2[0].aggregate_groups.each {|x| puts x.props.inspect}
    @set2[0].aggregate_groups.to_a.size.should == 1

    agg1 << agg2

    @set2[0].aggregate_groups.to_a.size.should == 2
    @set2[0].aggregate_groups.to_a.should include(agg1[:red], agg2[1])
  end

end
