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
    p1.outgoing(:friends).should include(p2, p3)
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
    n  = p1.friends_rels.map { |r| r.end_node }
    n.size.should == 2
    n.should include(p2)
    n.should include(p3)
  end

  it "method 'type'_rels returns an RelationshipTraverser which allows to finding a specific OUTGOING relationship" do
    p1 = Person.new
    p2 = Neo4j::Node.new
    p3 = Neo4j::Node.new
    p1.outgoing(:friends) << p2 << p3


    p1.friends_rels.to_other(p2).size.should == 1
    n  = p1.friends_rels.to_other(p2).map { |r| r.end_node }
    n.size.should == 1
    n.should include(p2)
  end

  it "method 'type'_rels returns an RelationshipTraverser which allows to finding a specific INCOMING relationship" do
    p1 = Person.new
    p2 = Person.new
    p3 = Person.new
    p1.outgoing(:friends) << p3
    p2.outgoing(:friends) << p3

    p3.friend_by.should include(p1, p2)
    p3.friend_by_rels.to_other(p1).size.should == 1
    p3.friend_by_rels.to_other(p1).map { |r| r.start_node }.should include(p1)
  end

  it "method 'type'_rels returns an RelationshipTraverser which has a method for deleting all relationships" do
    p1 = Person.new
    p2 = Person.new
    p3 = Person.new
    p1.friends << p2 << p3

    p1.friends.should include(p2,p3)

    p1.friends_rels.to_other(p2).del

    p1.friends.should_not include(p2)
    new_tx
    p2.should exist
  end

  it "can navigate a incoming relationship (has_n(:employed_by).from(Company, :employees))" do
    p1     = Person.new
    p2     = Person.new

    jayway = Company.new
    jayway.employees << p1 << p2

    google = Company.new
    google.employees << p1

    # then
    p1.employed_by.size.should == 2
    p2.employed_by.size.should == 1
    p1.employed_by.should include(jayway, google)
    p2.employed_by.should include(jayway)
    jayway.employees.should include(p1, p2)
    google.employees.should include(p1)
  end

  it "has_one/has_n: one-to-many, e.g. director --directed -*> movie" do
    lucas       = Director.new :name => 'George Lucas'
    star_wars_4 = Movie.new :title => 'Star Wars Episode IV: A New Hope', :year => 1977
    star_wars_3 = Movie.new :title => "Star Wars Episode III: Revenge of the Sith", :year => 2005
    lucas.directed << star_wars_3 << star_wars_4

    # then
    lucas.directed.should include(star_wars_3, star_wars_4)
    lucas.outgoing("Movie#directed").should include(star_wars_3, star_wars_4)
    star_wars_3.incoming("Movie#directed").should include(lucas)
    star_wars_3.director.should == lucas
    star_wars_4.director.should == lucas
  end
end
