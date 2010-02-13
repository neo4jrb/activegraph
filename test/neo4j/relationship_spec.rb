$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'spec_helper'


describe "Neo4j::Relationship" do

  before(:all) do
    start
  end

  after(:all) do
    stop
  end
  
  it "#initialize(:friends, node1, node2) should create a new relationship" do
    Neo4j::Transaction.run do
      node1 = Neo4j::Node.new
      node2 = Neo4j::Node.new

      # when
      rel = Neo4j::Relationship.new(:friend, node1, node2)

      # then
      node1.rels.outgoing(:friend).nodes.should include(node2)
      node1.rel(:friend).end_node.should == node2
      rel.should be_kind_of(Java::org.neo4j.graphdb.Relationship)
    end
  end

  it "#initialize(:friends, node1, node2, :since => '2010', :statue => true) should set two properties on the new relationship" do
      Neo4j::Transaction.run do
        node1 = Neo4j::Node.new
        node2 = Neo4j::Node.new

        # when
        rel = Neo4j::Relationship.new(:friend, node1, node2, :since => '2010', :status => true)

        # then
        rel[:since].should == '2010'
        rel[:status].should be_true
      end
    end

end
