$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'


class MyAggregateNode
  include Neo4j::NodeMixin
  include Neo4j::AggregateNodeMixin
end

class MyNode
  include Neo4j::NodeMixin
end


describe "Aggregates that are updated on event" do
  before(:each) do
    start
    Neo4j::Transaction.new
  end

  after(:each) do
    stop
  end

  it "should add nodes to the aggreate when a new node is created" do
    agg = MyAggregateNode.new
    registration = agg.aggregate(MyNode).group_by(:city)
    agg.aggregate_size.should == 0

    # when
    node = MyNode.new
    node[:city] = 'malmoe'

    # then
    agg.aggregate_size.should == 1
    agg['malmoe'].should include(node)

    registration.unregister # so that this spec does not have any side effects
  end

  it "should move aggregate group of a node when it changes a property" do
    agg = MyAggregateNode.new
    registration = agg.aggregate(MyNode).group_by(:city)
    node = MyNode.new
    node[:city] = 'malmoe'
    agg.aggregate_size.should == 1
    agg['malmoe'].should include(node)

    # when
    node[:city] = 'stockholm'

    # then
    agg.aggregate_size.should == 1
    agg['malmoe'].should be_nil
    agg['stockholm'].should include(node)

    registration.unregister # so that this spec does not have any side effects
  end

  it "should put a node into two groups when it is grouped by two properties" do
    # given an aggregate with groups by two properties
    agg = MyAggregateNode.new
    registration = agg.aggregate(MyNode).group_by(:city, :age)
    node = MyNode.new

    # when
    node[:city] = 'malmoe'
    node[:age] = 10

    # then
    agg.aggregate_size.should == 2
    agg['malmoe'].should include(node)
    agg[10].should include(node)
    registration.unregister # so that this spec does not have any side effects
  end

  it "should move group of a node when one property changes but keep the remaining groups" do
    # given an aggregate with groups by two properties
    agg = MyAggregateNode.new
    registration = agg.aggregate(MyNode).group_by(:city, :age)
    node = MyNode.new
    node[:city] = 'malmoe'
    node[:age] = 10

    # when
    node[:age] = 7

    # then
    agg.aggregate_size.should == 2
    agg['malmoe'].should include(node)
    agg[10].should be_nil
    agg[7].should include(node)
    registration.unregister # so that this spec does not have any side effects
  end

  it "should work for several nodes" do
    agg = MyAggregateNode.new
    registration = agg.aggregate(MyNode).group_by(:age)

    # when
    10.times {|i| node = MyNode.new; node[:age] = i}

    # then
    agg.aggregate_size.should == 10

    10.times {|i| agg[i].to_a[0][:age].should == i}
    10.times {|i| agg[i].aggregate_size.should == 1}


    registration.unregister # so that this spec does not have any side effects
  end


  it "should also work for map_value" do
    agg = MyAggregateNode.new
    registration = agg.aggregate(MyNode).group_by(:age).map_value{|x| x * 2}

    # when
    node = MyNode.new; node[:age] = 10

    # then
    agg[20].should include(node)
  end


  it "should delete nodes to the aggregate when a new node is created" do
    agg = MyAggregateNode.new
    registration = agg.aggregate(MyNode).group_by(:city)
    node = MyNode.new
    node[:city] = 'malmoe'
    agg.aggregate_size.should == 1

    # when
    node.delete

    # then
    agg.aggregate_size.should == 0
    agg['malmoe'].should be_nil
    registration.unregister # so that this spec does not have any side effects
  end


  it "should allow to create several groups from the same property" do
    # let say we both want to create groups young, old and groups for each age
    # given
    agg = MyAggregateNode.new
    registration = agg.aggregate(MyNode).group_by(:age).map_value{|age| [age < 6 ? "young" : "old", age / 5]}

    # when
    young = MyNode.new
    young[:age] = 4

    old = MyNode.new
    old[:age] = 40

    # then
    agg["young"].should include(young)
    agg["old"].should include(old)

    # check age group (age / 5)
    agg[0].should include(young)
    agg[8].should include(old)

    # there should be total 4 groups, young,old, 0 and 8
    agg.aggregate_size.should == 4

    registration.unregister # so that this spec does not have any side effects
  end
  
  it "should work on a tree of aggregates" do
    agg_root = MyAggregateNode.new

    # create an aggregate where all the members have the same score
    # update the aggregate when a node of type MyNode changes
    reg1 = agg_root.aggregate(MyNode).group_by(:score)

    # create another aggregation where the members have the same score group
    # define 4 score groups where
    # 0 - awful
    # 1-9 - bad
    # 10-99 - average
    # 100-999 - good
    # make this aggregate be the parent aggregate of the previous (reg1) aggregate
    scores = %w[awful bad average good]
    reg2 = agg_root.aggregate(reg1).group_by(:score).map_value{|score| scores[score.to_s.size]}

    # when
    n1 = MyNode.new; n1[:score] = 1
    n2 = MyNode.new; n2[:score] = 20
    n3 = MyNode.new; n3[:score] = 30
    n4 = MyNode.new; n4[:score] = 101
    n5 = MyNode.new; n5[:score] = 101
    n6 = MyNode.new; n6[:score] = 102

    # then
    agg_root.aggregate_size.should == 3
    agg_root["bad"].aggregate_size.should == 1
    agg_root["average"].aggregate_size.should == 2

    # there are two sub groups, one groop with same score 101 and another group with score 102
    agg_root["good"].aggregate_size.should == 2

    agg_root["good"][101].aggregate_size.should == 2
    agg_root["good"][101].should include(n4, n5)
  end

  it "should work on a tree of aggregates when nodes are deleted" do
    agg_root = MyAggregateNode.new

    # create an aggregate where all the members have the same score
    # update the aggregate when a node of type MyNode changes
    reg1 = agg_root.aggregate(MyNode).group_by(:score)

    # create another aggregation where the members have the same score group
    # define 4 score groups where
    # 0 - awful
    # 1-9 - bad
    # 10-99 - average
    # 100-999 - good
    # make this aggregate be the parent aggregate of the previous (reg1) aggregate
    scores = %w[awful bad average good]
    reg2 = agg_root.aggregate(reg1).group_by(:score).map_value{|score| scores[score.to_s.size]}

    n1 = MyNode.new; n1[:score] = 1
    n2 = MyNode.new; n2[:score] = 20
    n3 = MyNode.new; n3[:score] = 30
    n4 = MyNode.new; n4[:score] = 101
    n5 = MyNode.new; n5[:score] = 101
    n6 = MyNode.new; n6[:score] = 102

    # when
    n1.delete

    # then
    agg_root.aggregate_size.should == 2
    agg_root["bad"].should be_nil
    agg_root["average"].aggregate_size.should == 2

    # there are two sub groups, one groop with same score 101 and another group with score 102
    agg_root["good"].aggregate_size.should == 2
    agg_root["good"][101].aggregate_size.should == 2
    agg_root["good"][101].should include(n4, n5)
  end


  it "should work on a tree of aggregates when node property are changed" do
    agg_root = MyAggregateNode.new

    # create an aggregate where all the members have the same score
    # update the aggregate when a node of type MyNode changes
    reg1 = agg_root.aggregate(MyNode).group_by(:score)

    # create another aggregation where the members have the same score group
    # define 4 score groups where
    # 0 - awful
    # 1-9 - bad
    # 10-99 - average
    # 100-999 - good
    # make this aggregate be the parent aggregate of the previous (reg1) aggregate
    scores = %w[awful bad average good]
    reg2 = agg_root.aggregate(reg1).group_by(:score).map_value{|score| scores[score.to_s.size]}

    n1 = MyNode.new; n1[:score] = 1
    n2 = MyNode.new; n2[:score] = 20
    n3 = MyNode.new; n3[:score] = 30
    n4 = MyNode.new; n4[:score] = 101
    n5 = MyNode.new; n5[:score] = 101
    n6 = MyNode.new; n6[:score] = 102
    agg_root.aggregate_size.should == 3


    # when
    n1[:score] = 102

    # then
    agg_root.aggregate_size.should == 2
    agg_root["bad"].should be_nil
    agg_root["average"].aggregate_size.should == 2

    # there are two sub groups, one groop with same score 101 and another group with score 102
    agg_root["good"].aggregate_size.should == 2
    agg_root["good"][102].aggregate_size.should == 2
    agg_root["good"][102].should include(n6, n1)
  end

end


describe "Aggregated nodes that are grouped by one property (colour)" do
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


describe "Aggregate nodes that are grouped by each property" do
  before(:all) do
    start
    Neo4j::Transaction.new
  end

  after(:all) do
    stop
  end

  it "should create groups for each property value" do
    node1 = Neo4j::Node.new; node1[:colour] = 'red'; node1[:type] = 'A'
    node2 = Neo4j::Node.new; node2[:colour] = 'red'; node2[:type] = 'B'

    agg_node = MyAggregateNode.new
    agg_node.aggregate([node1, node2]).group_by(:colour, :type)

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

describe "Aggregate that are grouped by one property" do
  before(:each) do
    start
    Neo4j::Transaction.new
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

    @aggregate_node = MyAggregateNode.new
  end

  after(:each) do
    stop
  end

  it "should allow to create several groups from the same property" do
    # let say we both want to create groups young, old and groups for each age
    # given
    @aggregate_node.aggregate(@people).group_by(:age).map_value{|age| [age < 6 ? "young" : "old", age / 5]}

    # then
    @aggregate_node['young'].should include(@people[0], @people[1], @people[2], @people[3])
    @aggregate_node['old'].should include(@people[4], @people[5])

    @aggregate_node[0].to_a.size.should == 2
    @aggregate_node[2].to_a.size.should == 1
    @aggregate_node[2].should include(@people[5])
  end

  it "should allow to remap the group key" do
    # Creates age group 0=0-4, 1=5-9, 2=10-14
    @aggregate_node.aggregate(@people).group_by(:age).map_value{|age| age / 5}

    # then
    @aggregate_node[0].should include(@people[0], @people[1])
    @aggregate_node[0].to_a.size.should == 2
    @aggregate_node[2].to_a.size.should == 1
    @aggregate_node[2].should include(@people[5])
  end


  it "should have a counter for number of meber in each group" do
    # Creates age group 0=0-4, 1=5-9, 2=10-14
    @aggregate_node.aggregate(@people).group_by(:age).map_value{|age| age / 5}

    # then
    @aggregate_node.aggregate_size.should == 3 # there are 3 groups, 0-4, 5-9, 10-14
    @aggregate_node[0].aggregate_size.should == 2
    @aggregate_node[1].aggregate_size.should == 3
    @aggregate_node[2].aggregate_size.should == 1
  end

end


describe "Aggregate x and y coordinates into squares" do
  before(:all) do
    start
    Neo4j::Transaction.new

    # create positions (0,0), (1,2), (2,4), (3,6) ...
    @positions = []
    6.times {@positions << Neo4j::Node.new}
    @positions.each_with_index {|p, index| p[:x] = index}
    @positions.each_with_index {|p, index| p[:y] = index*2}
    @aggregate_node = MyAggregateNode.new
    @aggregate_node.aggregate(@positions).group_by(:x, :y).map_value{|x, y| (x/3)*3+(y/3)}
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


  it "should work with aggregates on aggregates" do
    agg_root = MyAggregateNode.new

    n1 = MyNode.new; n1[:latitude] = 10.3; n1[:longitude] = 5.2
    n2 = MyNode.new; n2[:latitude] = 5.94; n2[:longitude] = 52.4
    n3 = MyNode.new; n3[:latitude] = 5.24; n3[:longitude] = 52.9

    # create an aggrgeation of groups where members have the same latitude longitude integer values (to_i)
    reg1 = agg_root.aggregate().group_by(:latitude, :longitude).map_value{|lat, lng| "#{(lat*10).to_i}_#{(lng*10).to_i}"}

    # create another aggregation of groups where members have the same latitude longitude 1/10 value
    reg2 = agg_root.aggregate(reg1).group_by(:latitude, :longitude).map_value{|lat, lng| "#{lat.to_i}_#{lng.to_i}" }

    # when
    agg_root << n1 << n2 << n3

    # then
    agg_root["10_5"]["103_52"].should include(n1)
    agg_root["5_52"]["59_524"].should include(n2)

    agg_root.aggregate_size.should == 2
    agg_root["5_52"].aggregate_size.should == 2
    agg_root["10_5"].aggregate_size.should == 1

    # clean up
    reg1.unregister # so that this spec does not have any side effects
    reg2.unregister # so that this spec does not have any side effects
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
    agg_node.aggregate(@all).group_by(:colour)

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
    agg_node.aggregate(@all).group_by(:colour)

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


describe "Aggregates, each node should know which aggregate(s) it belongs to" do
  before(:each) do
    start

    Neo4j::Transaction.new
    @set = []
    4.times {@set << Neo4j::Node.new}
    @set[0][:colour] = 'red';  @set[0][:name] = "a"
    @set[1][:colour] = 'red';  @set[1][:name] = "b"
    @set[2][:colour] = 'red';  @set[2][:name] = "c"
    @set[3][:colour] = 'blue'; @set[3][:name] = "d"



    # aggreate first on name
    @agg1 = MyAggregateNode.new
    @agg1.aggregate(@set).group_by(:name).execute

    #use this name aggregate and aggregate on colour
    #
    # agg1      set         agg2
    #  a  --  @set[0] --+
    #  b  --  @set[1] --+-- red
    #  c  --  @set[2] --+
    #  d  --  @set[3] ----  blue
    #
    @agg2 = MyAggregateNode.new
    @agg2.aggregate(@set).group_by(:colour).execute
  end

  after(:each) do
    stop
  end

  it "should know which aggregate it belongs to"  do
    @set[0].aggregates.to_a.size.should == 2
    @set[1].aggregates.to_a.size.should == 2
    @set[0].aggregates.should include(@agg1, @agg2)
  end

  it "should know which aggregate group it belongs to" do
    # set[0] should belong to group agg1[a] and agg2[red]
    @set[0].aggregate_groups.to_a.size.should == 2
    @set[0].aggregate_groups.should include(@agg1['a'], @agg2['red'])

    # set[2] should belong to group agg1[c] and agg2[red]
    @set[2].aggregate_groups.to_a.size.should == 2
    @set[2].aggregate_groups.should include(@agg1['c'], @agg2['red'])

    # set[3] should belong to group agg[d] and agg2[blue]
    @set[3].aggregate_groups.to_a.size.should == 2
    @set[3].aggregate_groups.should include(@agg1['d'], @agg2['blue'])
  end

  it "should find the group direct by node.aggregate_group(<group_name>)" do
    @set[0].aggregate_groups('a').should == @agg1['a']
    @set[2].aggregate_groups('c').should == @agg1['c']
    @set[2].aggregate_groups('red').should == @agg2['red']
  end

end


describe "Aggregates, the << operator" do
  before(:each) do
    start

    Neo4j::Transaction.new
    @set = []
    4.times {@set << Neo4j::Node.new}
    @set[0][:colour] = 'red';  @set[0][:name] = "a"
    @set[1][:colour] = 'blue'; @set[1][:name] = "b"
    @set[2][:colour] = 'red';  @set[2][:name] = "c"
    @set[3][:colour] = 'blue'; @set[3][:name] = "d"

    # given
    # agg          set
    # red --+--  @set[0]
    #       |
    #       +--  @set[2]
    #
    # blue  +--  @set[1]
    #       |
    #       +--  @set[3]
    #
    @agg = MyAggregateNode.new
    @agg.aggregate(@set).group_by(:colour).execute
  end

  after(:all) do
    stop
  end


  it "should allow to append one node to an existing aggregate group" do
    new_node1 = Neo4j::Node.new
    new_node1[:colour] = 'blue'

    # when
    @agg << new_node1

    # then

    @agg[:blue].aggregate_size.should == 3
    @agg[:blue].should include(new_node1)
  end


  it "should allow to append one node to a new aggregate group" do
    new_node1 = Neo4j::Node.new
    new_node1[:colour] = 'black'

    @agg.aggregate_size.should == 2 # only

    # when
    @agg << new_node1

    # then
    @agg.aggregate_size.should == 3
    @agg[:black].should include(new_node1)
  end

  it "should allow to append an enumeration of nodes" do
    new_node1 = Neo4j::Node.new
    new_node1[:colour] = 'black'
    new_node2 = Neo4j::Node.new
    new_node2[:colour] = 'red'

    @agg.aggregate_size.should == 2 # only

    # when
    @agg << [new_node1, new_node2]

    # then
    @agg.aggregate_size.should == 3
    @agg[:black].should include(new_node1)
    @agg[:red].should include(new_node2)
  end

end

describe "Aggregates, over another aggregate" do
  before(:each) do
    start

    Neo4j::Transaction.new
    @set = []
    4.times {@set << Neo4j::Node.new}
    @set[0][:colour] = 'red';  @set[0][:name] = "a"
    @set[1][:colour] = 'red';  @set[1][:name] = "b"
    @set[2][:colour] = 'red';  @set[2][:name] = "c"
    @set[3][:colour] = 'blue'; @set[3][:name] = "d"
  end

  after(:all) do
    stop
  end

  it "should allow to aggregate aggregate groups" do
    # given
    # agg2     agg1      set
    #       +-- a  --  @set[0]
    # red --|-- b  --  @set[1]
    #       +-- c  --  @set[2]
    # blue ---- d  --  @set[3]
    #
    agg1 = MyAggregateNode.new
    agg1.aggregate(@set).group_by(:name)

    # when
    agg2 = MyAggregateNode.new
    agg2.aggregate(agg1).group_by(:colour)

    # then
    agg2.aggregate_size.should == 2
    agg2['red'].aggregate_size.should == 3
    agg2['red'].should include(agg1['a'], agg1['b'], agg1['c'])

    agg2['blue'].aggregate_size.should == 1
    agg2['blue'].should include(agg1['d'])
  end

  it "should know which aggregate it belongs to"  do
    pending "aggregate groups does not implement correctly Neo4j::NodeMixin#aggregates"
    agg1 = MyAggregateNode.new
    agg1.aggregate(@set).group_by(:name)

    # when
    agg2 = MyAggregateNode.new
    agg2.aggregate(agg1).group_by(:colour)

    # then
    agg1['a'].aggregates.to_a.size.should == 1
    @set[0].aggregates.to_a.size.should == 1

    @set[0].aggregates.to_a.should include(agg1)
    agg1['a'].aggregates.to_a.should include(agg2)
  end

  it "should know which aggregate groups it belongs to"  do
    pending "aggregate groups does not implement correctly Neo4j::NodeMixin#aggregates"
    agg1 = MyAggregateNode.new
    agg1.aggregate(@set).group_by(:name)

    # when
    agg2 = MyAggregateNode.new('agg2')
    agg2.aggregate(agg1).group_by(:colour)

    # then
    agg1['a'].aggregate_groups.to_a.size.should == 1
    @set[0].aggregate_groups.to_a.size.should == 1

    @set[0].aggregate_groups.to_a.should include(agg1['a'])
    agg1['a'].aggregate_groups.to_a.should include(agg2['red'])
  end

end
