$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'

describe "Readme Examples" do

  #before(:all) do
  #  stop
  #end

  # Called after each example.
  after(:all) do
    stop
  end

  it "should run: Example of setting properties" do
    node = Neo4j::Node.new
    node[:name] = 'foo'
    node[:age]  = 123
    node[:hungry] = false
  end

  it "should run: Example of getting properties" do
    node = Neo4j::Node.new
    node[:name] = 'foo'
    node[:name].should == 'foo'  
  end

  it "should run: Example of creating a relationship" do
    node1 = Neo4j::Node.new
    node2 = Neo4j::Node.new
    node1.relationships.outgoing(:friends) << node2
  end

  it "should run: Example of getting relationships" do
    node1 = Neo4j::Node.new
    node2 = Neo4j::Node.new
    node1.relationships.outgoing(:friends) << node2
    
    node1.relationships.nodes.include?(node2).should be_true # => true - it implements enumerable and other methods
    node1.relationships.empty?.should be_false # => false
    node1.relationships.first.should_not be_nil # => the first relationship this node1 has which is between node1 and node2
    node1.relationships.outgoing.nodes.first.should == node2 # => node2
    node1.relationships.outgoing(:friends).first.neo_relationship_id.should == node1.relationships.first.neo_relationship_id # => the first relationship of type :friends
  end

end

