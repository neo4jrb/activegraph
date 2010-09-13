require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::NodeMixin, "#has_n", :type => :transactional do

  it "operator << adds nodes to the declared relationship" do
    p1 = Person.new
    p2 = Person.new

    # when
    p1.friends << p2

    # then
    p1.outgoing(:friends).should include(p2)
  end

  it "operator << can be chained (<< n1 << n2)" do
    p1 = Person.new
    p2 = Person.new
    p3 = Person.new

    # when
    p1.friends << p2 << p3

    # then
    p1.outgoing(:friends).should include(p2,p3)
  end

  it "returns an Enumerable nodes of the declared relationship type" do
    p1 = Person.new
    p2 = Person.new
    p1.outgoing(:friends) << p2

    # when and then
    p1.friends.should include(p2)
  end

  it "returns an Enumerable nodes with real Ruby wrapped classes" do
    p1 = Person.new
    p2 = Person.new
    p1.outgoing(:friends) << p2

    # when and then
    p1.friends.first.class.should == Person
  end

  it "generates a 'type'_rels method for traversing relationships" do
    p1 = Person.new
    p2 = Neo4j::Node.new
    p3 = Neo4j::Node.new
    p1.outgoing(:friends) << p2 << p3

    [*p1.friends_rels].size.should == 2
    n = p1.friends_rels.map {|r| r.end_node}
    n.size.should == 2
    n.should include(p2)
    n.should include(p3)
  end
end
