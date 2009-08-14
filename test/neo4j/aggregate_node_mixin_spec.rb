$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'


class ColourAggregateNode
  include Neo4j::NodeMixin
  include Neo4j::AggregateNodeMixin
end

describe "Aggregated nodes grouped by one property" do
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
    # create names a,b,c,d,a,b.c,d,a,b,c,d
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
    @agg_node = ColourAggregateNode.new
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
    names.should include('a','b','c','d')
  end

  it "should aggregate properties on all aggregated nodes, e.g find name of all people" do
    names = @agg_node.aggregate(:colour)[:name].to_a
    puts "NAME #{names.to_a.inspect}"
    names.to_a.size.should == @all.to_a.size # duplicated name 'd'
    names.to_a.should include('a','b','c','d')
  end

end


#  it "should count all colours" do
#    # Each aggregated node also contains a counter
#    a = ColourAggregateNode.new
#    a.create_aggregate(:colours).with(@all).group_by(:colour).execute
#    a.count(:colour, 'red').should == 5
#    a.count(:colour, 'blue').should == 4
#    a.count(:colour, 'black').should == 3
#    a.count(:colour, 'pink').should == 0
#  end
#
#
#end
#
#
#class AgeGroupAggregateNode
#  include Neo4j::NodeMixin
#  include Neo4j::AggregateNodeMixin
#end
#
#describe "Aggregate people into age groups 0-4, 5-9, 10-14" do
#  before(:all) do
#    start
#    Neo4j.load_reindexer
#
#    Neo4j::Transaction.run do
#      @people = []
#      6.times {@people << Neo4j::Node.new}
#      @people[0][:age] = 2
#      @people[1][:age] = 4
#      @people[2][:age] = 5
#      @people[3][:age] = 5
#      @people[4][:age] = 9
#      @people[5][:age] = 10
#      # group 0 (0-4) - two people
#      # group 1 (5-9) - three people
#      # group 2 (10-14) - one person
#    end
#  end
#
#  after(:all) do
#    stop
#  end
#
#  before(:each) do
#    Neo4j::Transaction.new
#  end
#
#  after(:each) do
#    Neo4j::Transaction.finish
#  end
#
#  it "should traverse all people in an age group" do
#    #     @people[0],@people[1]<*----[aggregated node, prop age_group=0]<----<relation: 0>--[node a] ----<relation: 1>-->[aggregated node, prop age_group=1]--->@people[2],@people[3].@people[4]
#    #                                                                                      |
#    #                                                                                      V
#    #                                                                                <relation: 2>--...
#    a = AgeGroupAggregateNode.new
#    a.aggregate(@people).with_key(:age_group).of_unique_value{self[:age]/5}.execute
#    a.traverse_aggregate(:age_group, 0).to_a.size.should == 2
#    a.traverse_aggregate(:age_group, 0).should include(@people[0], @people[1])
#    a.traverse_aggregate(:age_group, 2).to_a.size.should == 1
#    a.traverse_aggregate(:age_group, 2).should include(@people[5])
#  end
#
#  it "should count number of people in each age group" do
#    a = AgeGroupAggregateNode.new
#    a.aggregate(@people).with_key(:age_group).of_unique_value{self[:age]/5}.execute
#    a.count(:age_group, 0).should == 2
#    a.count(:age_group, 1).should == 3
#    a.count(:age_group, 2).should == 1
#    a.count(:age_group, 3).should == 0
#  end
#
#
#end
