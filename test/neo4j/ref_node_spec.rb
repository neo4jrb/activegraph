$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'

describe 'ReferenceNode' do
  before(:all) do
    start
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
  
  it "can allow to create my own relationships from the reference node" do
    # given
    Neo4j.ref_node.relationships.outgoing(:myfoo).empty?.should be_true
    node = Neo4j::Node.new

    # when
    Neo4j.ref_node.relationships.outgoing(:myfoo) << node

    # then
    Neo4j.ref_node.relationships.outgoing(:myfoo).nodes.should include(node)
    Neo4j.ref_node.relationships.outgoing(:myfoo).to_a.size.should == 1    
  end


  it "can allow to create my own properties on the reference node" do
    # given
    Neo4j.ref_node[:kalle].should be_nil

    # when
    Neo4j.ref_node[:kalle] = 123

    # then
    Neo4j.ref_node[:kalle].should == 123
  end

end

