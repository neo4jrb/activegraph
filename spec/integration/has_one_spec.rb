require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::NodeMixin, "#has_one", :type => :transactional do


  it "assignment operator '=' creates a relationship" do
    person         = Person.new
    a              = Neo4j::Node.new
    person.address = a
    person.outgoing(:address).first.should == a
  end


  it "assignment operator '=' creates a relationship and deletes any previous relationship" do
    person         = Person.new
    a              = Neo4j::Node.new
    person.address = a
    a.incoming(:address).first.should == person

    b              = Neo4j::Node.new
    person.address = b

    # then
    [*a.rels].size.should == 0
    Neo4j::Node.load(b.neo_id).should == b # make sure the old node was not deleted - old bug
    person.outgoing(:address).first.should == b
  end

  it "create an accessor method named 'type' which return the other node" do
    person         = Person.new
    a              = Neo4j::Node.new
    person.address = a
    person.address.should == a
  end

  it "create an accessor method named 'type'_rel which return the relationship between the two nodes (or nil if none)" do
    person         = Person.new
    person.address_rel.should == nil

    a              = Neo4j::Node.new
    person.address = a

    person.address_rel.end_node.should == a
  end


  it "has one to one - can add a relationship on an incoming rel type" do
    # And the other way
    sune            = Person.new :name => 'sune'
    sunes_phone     = Phone.new :phone_number => '2222'

    sunes_phone.person = sune  # same as sune.home_phone = sunes_phone

    #then
    sune.home_phone.should == sunes_phone
    sunes_phone.person.should == sune
  end
end