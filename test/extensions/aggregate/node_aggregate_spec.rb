$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../..")

require 'neo4j'
require 'neo4j/extensions/aggregate'
require 'spec_helper'


class MyNode
  include Neo4j::NodeMixin
end

NodeAggregate = Neo4j::Aggregate::NodeAggregate


describe Neo4j::Aggregate::NodeGroup do
  it "should return an enumeration of all properties on outgoing nodes" do
    Neo4j::Transaction.new
    group = Neo4j::Aggregate::NodeGroup.new
    node1 = Neo4j::Node.new{|n| n[:name] = 'node1'}
    node2 = Neo4j::Node.new{|n| n[:name] = 'node2'}

    group.rels.outgoing(:foo) << node1
    group.rels.outgoing(:foo) << node2

    [*group[:name]].should include('node1', 'node2')
    [*group[:name]].size.should == 2
    Neo4j::Transaction.finish
  end
end




describe Neo4j::Aggregate::NodeAggregateMixin do
  before(:each) do
    start
    Neo4j::Transaction.new
    @registrations = []
  end

  after(:each) do
    stop
    @registrations.each {|reg| reg.unregister}
  end

  describe "#aggregate_size" do
    it "should be 0 when an node aggregate is created" do
      agg = NodeAggregate.new
      agg.aggregate_size.should == 0
    end


    it "should be 1 when a group is created" do
      agg = NodeAggregate.new
      @registrations << agg.aggregate(MyNode).group_by(:city)

      # when created
      node = MyNode.new
      node[:city] = 'malmoe'
      agg.aggregate_size.should == 1

      node2 = MyNode.new
      node2[:city] = 'stockholm'
      agg.aggregate_size.should == 2
    end

    it "should be 2 when two different groups has been created" do
      agg = NodeAggregate.new
      @registrations << agg.aggregate(MyNode).group_by(:city)

      # when two groups
      node = MyNode.new
      node[:city] = 'malmoe'
      agg.aggregate_size.should == 1
      node2 = MyNode.new
      node2[:city] = 'stockholm'

      # then
      agg.aggregate_size.should == 2
    end

    it "should be 1 when one group is created containing two nodes" do
      agg = NodeAggregate.new
      @registrations << agg.aggregate(MyNode).group_by(:city)

      # when create one group with two members
      node = MyNode.new
      node[:city] = 'malmoe'
      agg.aggregate_size.should == 1
      node2 = MyNode.new
      node2[:city] = 'malmoe'

      # then
      agg.aggregate_size.should == 1
    end
  end


  describe "#aggregate(Class).group_by(one property)" do
    it "should create group for a node when its property is set" do
      agg = NodeAggregate.new
      @registrations << agg.aggregate(MyNode).group_by(:city)
      agg.aggregate_size.should == 0

      # when
      node = MyNode.new
      node[:city] = 'malmoe'

      # then
      agg.aggregate_size.should == 1
      agg['malmoe'].should include(node)
    end

    it "should move group of a node when its property is changed" do
      agg = NodeAggregate.new
      @registrations << agg.aggregate(MyNode).group_by(:city)
      node = MyNode.new
      node[:city] = 'malmoe'

      # when
      node[:city] = 'stockholm'

      # then
      agg.aggregate_size.should == 1
      agg['malmoe'].should be_nil
      agg['stockholm'].should include(node)
    end

    it "should delete the group if the last node in that group is deleted" do
      agg = NodeAggregate.new
      @registrations << agg.aggregate(MyNode).group_by(:city)
      node = MyNode.new
      node[:city] = 'malmoe'
      agg['malmoe'].should include(node)

      # when
      node.del

      # then
      agg['malmoe'].should be_nil
    end

    it "should not delete the group when a member node is deleted if there are more nodes in that group " do
      agg = NodeAggregate.new
      @registrations << agg.aggregate(MyNode).group_by(:city)
      node = MyNode.new
      node[:city] = 'malmoe'

      node2 = MyNode.new
      node2[:city] = 'malmoe'
      agg['malmoe'].should include(node, node2)

      # when
      node.del

      # then
      agg['malmoe'].should include(node2)
      agg['malmoe'].should_not include(node)
    end

  end


  describe "#aggregate(Class).group_by(two properties)" do

    it "should put each node into two groups" do
      # given an aggregate with groups by two properties
      agg = NodeAggregate.new
      @registrations << agg.aggregate(MyNode).group_by(:city, :age)
      node = MyNode.new

      # when
      node[:city] = 'malmoe'
      node[:age] = 10

      # then
      agg.aggregate_size.should == 2
      agg['malmoe'].should include(node)
      agg[10].should include(node)
    end

    it "should move group of a node when one property changes but keep the remaining groups" do
      # given an aggregate with groups by two properties
      agg = NodeAggregate.new
      @registrations << agg.aggregate(MyNode).group_by(:city, :age)
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
    end

    it "should delete all its groups when a node is deleted and it was the last node in those groups" do
      # given an aggregate with groups by two properties
      agg = NodeAggregate.new
      @registrations << agg.aggregate(MyNode).group_by(:city, :age)
      node = MyNode.new
      node[:city] = 'malmoe'
      node[:age] = 10
      agg['malmoe'].should include(node)
      agg[10].should include(node)
      agg.aggregate_size.should == 2

      # delete
      node.del

      # then
      agg.aggregate_size.should == 0
      agg['malmoe'].should be_nil
      agg[10].should be_nil
    end


    it "should delete only empty groups when a node is deleted" do
      # given an aggregate with groups by two properties
      agg = NodeAggregate.new
      @registrations << agg.aggregate(MyNode).group_by(:city, :age)
      node = MyNode.new
      node[:city] = 'malmoe'
      node[:age] = 10
      node2 = MyNode.new
      node2[:city] = 'malmoe'

      agg['malmoe'].should include(node, node2)
      agg[10].should include(node)
      agg.aggregate_size.should == 2

      # delete
      node.del

      # then
      agg.aggregate_size.should == 1
      agg['malmoe'].should include(node2)
      agg[10].should be_nil
    end

  end

  describe "#aggregate(Class).group_by(one property).map_value{}" do

    it "should map a single property to one group" do
      agg = NodeAggregate.new
      @registrations << agg.aggregate(MyNode).group_by(:age).map_value{|x| x * 2}

      # when
      node = MyNode.new; node[:age] = 10

      # then
      agg[20].should include(node)
    end


    it "should map a single property to several groups" do
      # let say we both want to create groups young, old and groups for each age
      # given
      agg = NodeAggregate.new
      @registrations << agg.aggregate(MyNode).group_by(:age).map_value{|age| [age < 6 ? "young" : "old", age / 5]}

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
    end

  end

  describe "#aggregate(aggregate) - nested aggregates" do
    it "should allow to aggregate nodes in a tree of aggregates" do
      agg_root = NodeAggregate.new

      # create an aggregate where all the members have the same score
      # update the aggregate when a node of type MyNode changes
      reg1 = agg_root.aggregate(MyNode).group_by(:score)
      @registrations << reg1

      # create another aggregation where the members have the same score group
      # define 4 score groups where
      # 0 - awful
      # 1-9 - bad
      # 10-99 - average
      # 100-999 - good
      # make this aggregate be the parent aggregate of the previous (reg1) aggregate
      scores = %w[awful bad average good]
      @registrations << agg_root.aggregate(reg1).group_by(:score).map_value{|score| scores[score.to_s.size]}

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

      # there are two sub groups, one group with same score 101 and another group with score 102
      agg_root["good"].aggregate_size.should == 2

      agg_root["good"][101].aggregate_size.should == 2
      agg_root["good"][101].should include(n4, n5)
    end

    
    it "should delete parent aggregate group nodes when child aggregate group node is deleted" do
      agg_root = NodeAggregate.new

      # create an aggregate where all the members have the same score
      # update the aggregate when a node of type MyNode changes
      reg1 = agg_root.aggregate(MyNode).group_by(:score)
      @registrations << reg1

      # create another aggregation where the members have the same score group
      # define 4 score groups where
      # 0 - awful
      # 1-9 - bad
      # 10-99 - average
      # 100-999 - good
      # make this aggregate be the parent aggregate of the previous (reg1) aggregate
      scores = %w[awful bad average good]
      @registrations << agg_root.aggregate(reg1).group_by(:score).map_value{|score| scores[score.to_s.size]}

      n1 = MyNode.new; n1[:score] = 1
      n2 = MyNode.new; n2[:score] = 20
      n3 = MyNode.new; n3[:score] = 30
      n4 = MyNode.new; n4[:score] = 101
      n5 = MyNode.new; n5[:score] = 101
      n6 = MyNode.new; n6[:score] = 102

      # when
      n1.del

      # then
      agg_root.aggregate_size.should == 2
      agg_root["bad"].should be_nil
      agg_root["average"].aggregate_size.should == 2

      # there are two sub groups, one groop with same score 101 and another group with score 102
      agg_root["good"].aggregate_size.should == 2
      agg_root["good"][101].aggregate_size.should == 2
      agg_root["good"][101].should include(n4, n5)
    end


    it "should move the node in both parent and child aggregate groups when its property is changed" do
      agg_root = NodeAggregate.new

      # create an aggregate where all the members have the same score
      # update the aggregate when a node of type MyNode changes
      reg1 = agg_root.aggregate(MyNode).group_by(:score)
      @registrations << reg1

      # create another aggregation where the members have the same score group
      # define 4 score groups where
      # 0 - awful
      # 1-9 - bad
      # 10-99 - average
      # 100-999 - good
      # make this aggregate be the parent aggregate of the previous (reg1) aggregate
      scores = %w[awful bad average good]
      @registrations << agg_root.aggregate(reg1).group_by(:score).map_value{|score| scores[score.to_s.size]}

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


  describe "#aggregate(nodes).group_by(one property)" do
    # Called before each example.
    before(:each) do
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
      4.times { names += [*('a' .. 'd')]}
      @all.each {|n| n[:name] = names.pop}
      @agg_node = NodeAggregate.new
      @agg_node.aggregate(@all).group_by(:colour).execute
    end

    it "should create one group for each unique property value" do
      [*@agg_node].size.should == 3
    end

    it "should create groups with properties aggregate_group" do
      colours = @agg_node.inject([]) {|array, node| array << node.aggregate_group}
      colours.should include('red', 'blue', 'green')
    end

    it "should set the aggregate_size property to the number of created groups" do
      @agg_node.aggregate_size.should == 3
    end

    it "should have aggregate_size property for each group" do
      @agg_node[:red].aggregate_size.should == 5
      @agg_node[:blue].aggregate_size.should == 4
      @agg_node[:green].aggregate_size.should == 3
    end

    it "should aggregate properties on aggregated nodes, e.g find name of all people having favorite colour 'red'" do
      names = [*@agg_node[:red][:name]]
      names.size.should == 5 # duplicated name 'd'
      names.should include('a', 'b', 'c', 'd')
    end

    it "should not add nodes to the aggregation that does not have a group property" do
      # add a node that does not have the colour property
      [*@agg_node].size.should == 3
      @agg_node[:red].aggregate_size.should == 5
      @agg_node[:blue].aggregate_size.should == 4
      @agg_node[:green].aggregate_size.should == 3

      @agg_node << Neo4j::Node.new

      [*@agg_node].size.should == 3
      @agg_node[:red].aggregate_size.should == 5
      @agg_node[:blue].aggregate_size.should == 4
      @agg_node[:green].aggregate_size.should == 3
    end
  end


  describe "#aggregate(nodes).group_by(two properties)" do
    it "should create groups for each property value" do
      node1 = Neo4j::Node.new; node1[:colour] = 'red'; node1[:type] = 'A'
      node2 = Neo4j::Node.new; node2[:colour] = 'red'; node2[:type] = 'B'

      agg_node = NodeAggregate.new
      @registrations << agg_node.aggregate([node1, node2]).group_by(:colour, :type)

      agg_node['red'].aggregate_size.should == 2
      agg_node['A'].aggregate_size.should == 1
      agg_node['A'].aggregate_size.should == 1

      agg_node['A'].should include(node1)
      agg_node['B'].should include(node2)
      agg_node['red'].should include(node1, node2)

      [*node1.aggregate_groups].size.should == 2
      [*node2.aggregate_groups].size.should == 2
    end
  end

  describe "#aggregate(nodes).group_by(one property).map_value{}" do
    before(:each) do
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

      @aggregate_node = NodeAggregate.new
    end

    it "should allow to create several groups from the same property" do
      # let say we both want to create groups young, old and groups for each age
      # given
      @registrations << @aggregate_node.aggregate(@people).group_by(:age).map_value{|age| [age < 6 ? "young" : "old", age / 5]}

      # then
      @aggregate_node['young'].should include(@people[0], @people[1], @people[2], @people[3])
      @aggregate_node['old'].should include(@people[4], @people[5])

      [*@aggregate_node[0]].size.should == 2
      [*@aggregate_node[2]].size.should == 1
      @aggregate_node[2].should include(@people[5])
    end

    it "should allow to remap the group key" do
      # Creates age group 0=0-4, 1=5-9, 2=10-14
      @registrations << @aggregate_node.aggregate(@people).group_by(:age).map_value{|age| age / 5}

      # then
      @aggregate_node[0].should include(@people[0], @people[1])
      [*@aggregate_node[0]].size.should == 2
      [*@aggregate_node[2]].size.should == 1
      @aggregate_node[2].should include(@people[5])
    end


    it "should have a counter for number of member in each group" do
      # Creates age group 0=0-4, 1=5-9, 2=10-14
      @registrations << @aggregate_node.aggregate(@people).group_by(:age).map_value{|age| age / 5}

      # then
      @aggregate_node.aggregate_size.should == 3 # there are 3 groups, 0-4, 5-9, 10-14
      @aggregate_node[0].aggregate_size.should == 2
      @aggregate_node[1].aggregate_size.should == 3
      @aggregate_node[2].aggregate_size.should == 1
    end

  end


  describe "Spatial Index using Aggregates, x and y into tiles" do
    before(:each) do
      # create positions (0,0), (1,2), (2,4), (3,6) ...
      @positions = []
      6.times {@positions << Neo4j::Node.new}
      @positions.each_with_index {|p, index| p[:x] = index}
      @positions.each_with_index {|p, index| p[:y] = index*2}
      @aggregate_node = NodeAggregate.new
      @registrations << @aggregate_node.aggregate(@positions).group_by(:x, :y).map_value{|x, y| (x/3)*3+(y/3)}
    end

    it "should traverse all positions in a tile" do
      # find all coordinates in the square 0 - |0,0 2,0|
      #                                        |0,2 2,2|
      @aggregate_node[0].should include(@positions[0], @positions[1])
      @aggregate_node[0].aggregate_size.should == 2

      # find all coordinates in the square 1 - |0,3 2,3|
      #                                        |0,5 2,5|
      @aggregate_node[1].should include(@positions[2])
      @aggregate_node[1].aggregate_size.should == 1
    end


    it "should allow to aggregate (index) tiles in tiles" do
      agg_root = NodeAggregate.new

      n1 = MyNode.new; n1[:latitude] = 10.3; n1[:longitude] = 5.2
      n2 = MyNode.new; n2[:latitude] = 5.94; n2[:longitude] = 52.4
      n3 = MyNode.new; n3[:latitude] = 5.24; n3[:longitude] = 52.9

      # create an aggregate of groups where members have the same latitude longitude integer values (to_i)
      reg1 = agg_root.aggregate().group_by(:latitude, :longitude).map_value{|lat, lng| "#{(lat*10).to_i}_#{(lng*10).to_i}"}
      @registrations << reg1

      # create another aggregation of groups where members have the same latitude longitude 1/10 value
      @registrations << agg_root.aggregate(reg1).group_by(:latitude, :longitude).map_value{|lat, lng| "#{lat.to_i}_#{lng.to_i}" }

      # when
      agg_root << n1 << n2 << n3

      # then
      agg_root["10_5"]["103_52"].should include(n1)
      agg_root["5_52"]["59_524"].should include(n2)

      agg_root.aggregate_size.should == 2
      agg_root["5_52"].aggregate_size.should == 2
      agg_root["10_5"].aggregate_size.should == 1
    end

  end



  describe "#<< operator" do
    before(:each) do
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

    it "should add node into existing groups" do
      agg_node = NodeAggregate.new
      @registrations << agg_node.aggregate(@all).group_by(:colour)

      new_node = Neo4j::Node.new
      new_node[:colour] = 'green'
      agg_node[:green].aggregate_size.should == 3

      # when
      agg_node << new_node

      # then
      agg_node[:green].aggregate_size.should == 4
      agg_node[:green].should include(new_node)
    end

    it "should add node into new groups" do
      agg_node = NodeAggregate.new
      @registrations << agg_node.aggregate(@all).group_by(:colour)

      new_node = Neo4j::Node.new
      new_node[:colour] = 'black'
      agg_node[:black].should be_nil

      # when
      agg_node << new_node

      # then
      agg_node[:black].aggregate_size.should == 1
      agg_node[:black].should include(new_node)
    end

    it "should allow to add node into an empty aggregation" do
      agg_node = NodeAggregate.new
      @registrations << agg_node.aggregate.group_by(:colour)

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
      agg_node = NodeAggregate.new
      @registrations << agg_node.aggregate.group_by(:colour)

      new_node = Neo4j::Node.new
      new_node[:colour] = 'black'

      agg_node.include_node?(new_node).should be_false
      agg_node << new_node

      # when
      agg_node.include_node?(new_node).should be_true
    end
  end

end


