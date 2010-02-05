$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/extensions/graph_algo'
require 'spec_helper'

include Neo4j

describe "GraphAlgo.all_simple_path" do

  before(:all) do
    start
    Neo4j::Transaction.new

    @n1 = Node.new
    @n2 = Node.new
    @n3 = Node.new
    @n4 = Node.new
    @n5 = Node.new
    @n6 = Node.new
    @n1.rels.outgoing(:knows) << @n2
    @n1.rels.outgoing(:knows) << @n3
    @n1.rels.outgoing(:knows) << @n4

    @n3.rels.outgoing(:knows) << @n5
    @n4.rels.outgoing(:knows) << @n5

    @n5.rels.outgoing(:knows) << @n3
    @n5.rels.outgoing(:knows) << @n6

  end

  after(:all) do
    stop
  end


  it "should contain Enumerable of Enumerable" do
    paths = Neo4j::GraphAlgo.all_simple_paths.from(@n1).outgoing(:knows).to(@n5).depth(2)
    paths.size.should == 2
    [*paths][0].should be_kind_of Enumerable
    [*paths][1].should be_kind_of Enumerable
  end

  it "should contain Enumerable of Enumerable of alternating Relationship and Nodes" do
    paths = Neo4j::GraphAlgo.all_simple_paths.from(@n1).outgoing(:knows).to(@n5).depth(2)
    node = true
    node_and_rel_ids = []

    [*paths][0].each do | node_or_rel|
      if node
        node_or_rel.should be_kind_of org.neo4j.graphdb.Node
        node_and_rel_ids << node_or_rel.neo_id
      else
        node_or_rel.should be_kind_of org.neo4j.graphdb.Relationship
        node_and_rel_ids << node_or_rel.neo_id
      end
      node = !node
    end

    n1_n3 = @n1.rels.outgoing(:knows)[@n3]
    n3_n5 = @n3.rels.outgoing(:knows)[@n5]

    [@n1.neo_id, n1_n3.neo_id, @n3.neo_id, n3_n5.neo_id, @n5.neo_id].should == node_and_rel_ids
  end

  it "should contain Enumerable of Enumerable of only Nodes if as_nodes is given" do
    paths = Neo4j::GraphAlgo.all_simple_paths.from(@n1).outgoing(:knows).to(@n5).depth(2).as_nodes
    node_ids = []
    [*paths][0].each do | node|
      node.should be_kind_of org.neo4j.graphdb.Node
      node_ids << node.neo_id
    end
    [@n1.neo_id, @n3.neo_id, @n5.neo_id].should == node_ids
  end

  it "should take a depth parameter" do
    paths = Neo4j::GraphAlgo.all_simple_paths.from(@n1).outgoing(:knows).to(@n6).depth(1)
    paths.size.should == 0

    paths = Neo4j::GraphAlgo.all_simple_paths.from(@n1).outgoing(:knows).to(@n6).depth(3)
    paths.size.should == 2

    paths = Neo4j::GraphAlgo.all_simple_paths.from(@n1).outgoing(:knows).to(@n6).depth(2)
    paths.size.should == 0
  end

  it "should take a incoming and outgoing parameter" do
    paths = Neo4j::GraphAlgo.all_simple_paths.from(@n1).outgoing(:knows).to(@n6).depth(3)
    paths.size.should == 2

    paths = Neo4j::GraphAlgo.all_simple_paths.from(@n1).incoming(:knows).to(@n6).depth(3)
    paths.size.should == 0

    paths = Neo4j::GraphAlgo.all_simple_paths.from(@n6).outgoing(:knows).to(@n1).depth(3)
    paths.size.should == 0

    paths = Neo4j::GraphAlgo.all_simple_paths.from(@n6).incoming(:knows).to(@n1).depth(3)
    paths.size.should == 2
  end

  it "should take a both parameter" do
    paths = Neo4j::GraphAlgo.all_simple_paths.from(@n1).both(:knows).to(@n6).depth(3)
    paths.size.should == 3

    paths = Neo4j::GraphAlgo.all_simple_paths.from(@n6).both(:knows).to(@n1).depth(3)
    paths.size.should == 3
  end

end

