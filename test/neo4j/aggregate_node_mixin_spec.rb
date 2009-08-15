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
    #                                                                                   [node a]
    #                                                                                      |
    #                                                                                      V
    #     @blue nodes<*----[aggregated node, prop colour='blue']<----<rel type=blue>--[aggregate colour] ----<rel type=black>-->[aggregated node, prop colour='black']--->@black nodes
    #                                                                                      | <rel type=red>
    #                                                                                      V
    #                                                                                <relation: red>--->...
    @agg_node = MyAggregateNode.new
    @agg_node.create_aggregate(:colour).with(@all).group_by(:colour).execute
  end

  it "should have an enumeration of all groups" do
    @agg_node.aggregate(:colour).to_a.size.should == 3
  end
  it "should have group nodes with propertie aggregate_group" do
    colours = @agg_node.aggregate(:colour).inject([]) {|array, node| array << node.aggregate_group}
    colours.should include('red', 'blue', 'green')
  end

  it "should have the same aggregate_id for all group nodes" do
    aggregate_ids = @agg_node.aggregate(:colour).inject([]) {|array, node| array << node.aggregate_id}
    aggregate_ids.each {|id| aggregate_ids[0].should == id}
  end

  it "should have size property for how many groups there are" do
    @agg_node.aggregate(:colour).size.should == 3
  end

  it "should have size property for each group" do
    @agg_node.aggregate(:colour, :red).size.should == 5
    @agg_node.aggregate(:colour, :blue).size.should == 4
    @agg_node.aggregate(:colour, :green).size.should == 3
  end

  it "node.aggregate(:colour, :red) should be the same as node.aggregate(:colour).aggregate(:red)" do
    @agg_node.aggregate(:colour).aggregate(:red).to_a.size.should == @agg_node.aggregate(:colour, :red).to_a.size
    @agg_node.aggregate(:colour).aggregate(:green).size.should == @agg_node.aggregate(:colour, :green).size
  end

  it "should aggregate properties on aggregated nodes, e.g find name of all people having favorite colour 'red'" do
    names = @agg_node.aggregate(:colour).aggregate(:red)[:name].to_a
    names.size.should == 5 # duplicated name 'd'
    names.should include('a', 'b', 'c', 'd')
  end

  it "should aggregate properties on all aggregated nodes, e.g find name of all people" do
    names = @agg_node.aggregate(:colour)[:name].to_a
    puts "NAME #{names.to_a.inspect}"
    names.to_a.size.should == @all.to_a.size # duplicated name 'd'
    names.to_a.should include('a', 'b', 'c', 'd')
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
      @aggregate_node.create_aggregate(:age_groups).with(@people).group_by(:age).map_value{|age| age / 5}.execute
    end
  end

  after(:all) do
    stop
  end

  it "should traverse all people in an age group" do
    @aggregate_node.aggregate(:age_groups, 0).to_a.size.should == 2
    @aggregate_node.aggregate(:age_groups, 0).should include(@people[0], @people[1])
    @aggregate_node.aggregate(:age_groups, 2).to_a.size.should == 1
    @aggregate_node.aggregate(:age_groups, 2).should include(@people[5])
  end


  it "should count number of people in each age group" do
    @aggregate_node.aggregate(:age_groups).size.should == 3 # there are 3 groups, 0-4, 5-9, 10-14
    @aggregate_node.aggregate(:age_groups, 0).size.should == 2
    @aggregate_node.aggregate(:age_groups, 1).size.should == 3
    @aggregate_node.aggregate(:age_groups, 2).size.should == 1
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
      @aggregate_node.create_aggregate(:squares).with(@positions).group_by(:x, :y).map_value{|x, y| (x/3)*3+(y/3)}.execute
    end
  end

  after(:all) do
    stop
  end

  it "should traverse all positions in a square" do
    # find all coordinates in the square 0 - |0,0 2,0|
    #                                        |0,2 2,2|
    @aggregate_node.aggregate(:squares, 0).should include(@positions[0], @positions[1])
    @aggregate_node.aggregate(:squares, 0).size.should == 2

    # find all coordinates in the square 1 - |0,3 2,3|
    #                                        |0,5 2,5|
    @aggregate_node.aggregate(:squares, 1).should include(@positions[2])
    @aggregate_node.aggregate(:squares, 1).size.should == 1
  end

end

describe "Aggregate group_by_each" do
  before(:all) do
    start

    # Let say we have a lot of things with many different names: name1, name2, name3
    # We now want to group all things by name indepentent of which property the name is found in
    # create names a,b,c,a,b,c,a,b,c, ...
    names = []
    4.times { names += ('a' .. 'c').to_a}

    @things = []
    Neo4j::Transaction.new

    5.times {@things << Neo4j::Node.new}
    # @things0 name1=a, name2=c
    # @things1 name1=b, name2=a
    # @things2 name1=c, name2=b
    # @things3 name1=a, name2=c
    # @things4 name1=b, name2=a

    @things.each {|t| t[:name1] = names.pop}  # name1= a,b,c,a,b
    @things.each {|t| t[:name2] = names.pop}  # name2= c,a,b,c,a

    @aggregate_node = MyAggregateNode.new
    # todo
#    @aggregate_node.create_aggregate(:names).with(@positions).group_by_each(:name1, :name2).execute
  end

  after(:all) do
    stop
  end

  it "should find all nodes" do
    pending
    @aggregate_node.aggregate(:names, 'a').should include(@things[0], @things[1], @things[3], @things[4])
    @aggregate_node.aggregate(:names, 'a').size.should == 4

    # find all coordinates in the square 1 - |0,3 2,3|
    #                                        |0,5 2,5|
    @aggregate_node.aggregate(:squares, 1).should include(@positions[2])
    @aggregate_node.aggregate(:squares, 1).size.should == 1
  end

end

