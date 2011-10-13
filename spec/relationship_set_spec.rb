require File.join(File.dirname(__FILE__), 'spec_helper')

describe "RelationshipSet" do
  before(:each) do
    @set = Neo4j::RelationshipSet.new
  end

  it "should return false contains for nonexistent entries" do
    @set.contains?(4,:foo).should be_false
  end

  it "should return true for registered entries" do
    new_tx
    node1 = Neo4j::Node.new
    node2 = Neo4j::Node.new

    rel   = Neo4j::Relationship.new(:relationship, node1, node2)
    finish_tx
    @set.add(rel)
    @set.contains?(node2.getId(),:relationship).should be_true
  end

  it "should return list of nodes attached to an end node across relationships" do
    new_tx
    node1 = Neo4j::Node.new
    node2 = Neo4j::Node.new
    node3 = Neo4j::Node.new

    rel1   = Neo4j::Relationship.new(:relationship, node1, node2)
    rel2   = Neo4j::Relationship.new(:relationship, node3, node2)
    finish_tx
    @set.add(rel1)
    @set.add(rel2)
    @set.relationships(node2.getId()).size.should == 2
    @set.relationships(node2.getId()).should include(rel1,rel2)
  end

  it "should return true if a relationship is contained" do
    new_tx
    node1 = Neo4j::Node.new
    node2 = Neo4j::Node.new
    node3 = Neo4j::Node.new

    rel1   = Neo4j::Relationship.new(:relationship, node1, node2)
    rel2   = Neo4j::Relationship.new(:relationship, node3, node2)
    finish_tx
    @set.add(rel1)
    @set.contains_rel?(rel1).should be_true
    @set.contains_rel?(rel2).should be_false
  end
end