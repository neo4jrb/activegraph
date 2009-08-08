$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'
require 'neo4j/extensions/reindexer'


class ColourAggregateNode
  include Neo4j::NodeMixin
  include Neo4j::AggregateNodeMixin
end

describe "Aggregate nodes with colour properties" do
  before(:all) do
    start
    Neo4j.load_reindexer

    Neo4j::Transaction.run do
      @red=[]
      @blue=[]
      @black=[]
      5.times {@red << Neo4j::Node.new}
      4.times {@blue << Neo4j::Node.new}
      3.times {@black << Neo4j::Node.new}
      @red.each {|n| n[:colour] = 'red'}
      @blue.each {|n| n[:colour] = 'blue'}
      @black.each {|n| n[:colour] = 'black'}
      @all = @red + @blue + @black
    end
  end

  after(:all) do
    stop
  end

  # Called before each example.
  before(:each) do
    Neo4j::Transaction.new
  end

  # Called after each example.
  after(:each) do
    Neo4j::Transaction.finish
  end

  it "should traverse nodes of specific colour" do
    # For all nodes that have the same colour create a new aggregate node with property 'colour'
    # The ColourAggregateNode has outgoing relationship of type blue, black, red to those aggegated nodes.
    # Each aggregated node has a property colour with the value of its related nodes. There will be three aggregated nodes with property blue, black and red.
    # Those nodes are connected to all nodes that have this property with the same relationship.
    #
    #     @blue nodes<*----[aggregated node, prop colour='blue']<----<relation: blue>--[node a] ----<relation: black>-->[aggregated node, prop colour='black']--->@black nodes
    #                                                                                      |
    #                                                                                      V
    #                                                                                <relation: red>--->...
    a = ColourAggregateNode.new
    a.aggregate(@all).with_key(:colour).of_unique_value{self[:colour]}.execute
    a.traverse_aggregate(:colour, "blue").to_a.size.should == 4
    a.traverse_aggregate(:colour, "blue").should include(*@blue)
    a.traverse_aggregate(:colour, "black").to_a.size.should == 3
    a.traverse_aggregate(:colour, "black").should include(*@black)
    a.traverse_aggregate(:colour, "pink").to_a.should be_empty
  end

  it "should count all colours" do
    # Each aggregated node also contains a counter 
    a = ColourAggregateNode.new
    a.aggregate(@all).with_key(:colour).of_unique_value{self[:colour]}.execute
    a.count(:colour, 'red').should == 5
    a.count(:colour, 'blue').should == 4
    a.count(:colour, 'black').should == 3
    a.count(:colour, 'pink').should == 0
  end


end


class AgeGroupAggregateNode
  include Neo4j::NodeMixin
  include Neo4j::AggregateNodeMixin
end

describe "Aggregate people into age groups 0-4, 5-9, 10-14" do
  before(:all) do
    start
    Neo4j.load_reindexer

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
    end
  end

  after(:all) do
    stop
  end

  before(:each) do
    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish
  end

  it "should traverse all people in an age group" do
    #     @people[0],@people[1]<*----[aggregated node, prop age_group=0]<----<relation: 0>--[node a] ----<relation: 1>-->[aggregated node, prop age_group=1]--->@people[2],@people[3].@people[4]
    #                                                                                      |
    #                                                                                      V
    #                                                                                <relation: 2>--...
    a = AgeGroupAggregateNode.new
    a.aggregate(@people).with_key(:age_group).of_unique_value{self[:age]/5}.execute
    a.traverse_aggregate(:age_group, 0).to_a.size.should == 2
    a.traverse_aggregate(:age_group, 0).should include(@people[0], @people[1])
    a.traverse_aggregate(:age_group, 2).to_a.size.should == 1
    a.traverse_aggregate(:age_group, 2).should include(@people[5])
  end

  it "should count number of people in each age group" do
    a = AgeGroupAggregateNode.new
    a.aggregate(@people).with_key(:age_group).of_unique_value{self[:age]/5}.execute
    a.count(:age_group, 0).should == 2
    a.count(:age_group, 1).should == 3
    a.count(:age_group, 2).should == 1
    a.count(:age_group, 3).should == 0
  end


end
