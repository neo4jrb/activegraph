require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::Relationship, :type=> :transactional do
  it "#end_node, #start_node and #other_node should return Ruby wrapped object" do
    p1 = SimpleNode.new
    p2 = SimpleNode.new
    p1.outgoing(:friends) << p2

    p1.rels(:friends).each do |rel|
      rel.start_node.should be_kind_of(SimpleNode)
      rel.end_node.should be_kind_of(SimpleNode)
      rel.other_node(rel.start_node).should be_kind_of(SimpleNode)
      rel.other_node(p1._java_node).should be_kind_of(SimpleNode)
      end
  end

  it "#end_node, #start_node and #other_node should return java node Object if there is no mapping for that node" do
    p1 = Neo4j::Node.new
    p2 = Neo4j::Node.new
    p1.outgoing(:friends) << p2

    p1.rels(:friends).each do |rel|
      rel.start_node.should be_kind_of(Java::org.neo4j.graphdb.Node)
      rel.end_node.should be_kind_of(Java::org.neo4j.graphdb.Node)
      rel.other_node(rel.start_node).should be_kind_of(Java::org.neo4j.graphdb.Node)
      end
  end

  it "#new(:family, p1, p2) creates a new relationship between to nodes of given type" do
    p1 = Neo4j::Node.new
    p2 = Neo4j::Node.new

    Neo4j::Relationship.new(:family, p1, p2)
    p1.outgoing(:family).should include(p2)
    p2.incoming(:family).should include(p1)
  end

  it "#new(:family, p1, p2, :since => '1998', :colour => 'blue') creates relationship and sets its properties" do
    p1 = Neo4j::Node.new
    p2 = Neo4j::Node.new

    rel = Neo4j::Relationship.new(:family, p1, p2, :since => 1998, :colour => 'blue')
    rel[:since].should == 1998
    rel[:colour].should == 'blue'
  end

  it "#outgoing(:friends).new(other) creates a new relationship between self and other node" do
    p1 = Neo4j::Node.new
    p2 = Neo4j::Node.new
    rel = p1.outgoing(:foo).new(p2)
    p1.outgoing(:foo).first.should == p2
    rel.should be_kind_of(org.neo4j.graphdb.Relationship)
  end
end
