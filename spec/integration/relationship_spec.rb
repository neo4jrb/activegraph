require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::Relationship, :type=> :integration do
  it "#rels(:friends)" do
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

end
