require File.join(File.dirname(__FILE__), 'spec_helper')

describe Neo4j, :type => :transactional do

  after(:each) { Neo4j.threadlocal_ref_node = nil }

  it "#ref_node returns the reference node" do
    Neo4j.ref_node.should be_kind_of(Java::org.neo4j.graphdb.Node)
  end

  it "should be able to change the reference node" do
    new_ref = Neo4j::Node.new
    Neo4j.threadlocal_ref_node = new_ref
    Neo4j.ref_node.should == new_ref._java_node
  end

  it "#ref_node, can have relationship to this node" do
    new_tx
    a = Neo4j::Node.new
    b = Neo4j::Node.new
    a.outgoing(:jo) << b
    lambda { Neo4j.ref_node.outgoing(:skoj) << a << b }.should change(Neo4j.ref_node.rels, :size).by(2)

    lambda { a.del; b.del }.should change(Neo4j.ref_node.rels, :size).by(-2)
  end


  it "#all_nodes returns a Enumerable of all nodes in the graph database " do
    # given created three nodes in a clean database
    created_nodes = 3.times.map { Neo4j::Node.new.id }

    # when
    found_nodes   = Neo4j.all_nodes.map { |node| node.id }

    # then
    found_nodes.should include(*created_nodes)
    found_nodes.should include(Neo4j.ref_node.id)
  end

  it "#management returns by default a management for Primitives", :edition => :advanced do
    Neo4j.management.get_number_of_node_ids_in_use.should > 0
  end
end
