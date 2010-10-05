require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::RelationshipMixin, :type=> :transactional do


  it "creates a relationship between the given nodes" do
    a = Neo4j::Node.new
    b = Neo4j::Node.new

    # when
    Friend.new(:friend, a,b)

    # then
    a.rel?(:friend).should be_true
    b.rel?(:friend).should be_true
    a.rels(:friend).outgoing.first.end_node.should == b
    b.rels(:friend).incoming.first.start_node.should == a
  end


  it "creates initializes the relationship with given properties" do
    a = Neo4j::Node.new
    b = Neo4j::Node.new

    # when
    Friend.new(:friend, a,b, :age => 2, :colour => 'blue')

    # then
    rel = a.rels(:friend).outgoing.first
    rel[:age].should == 2
    rel[:colour].should == 'blue'
  end


  it "can set properties with the []= operator and read it with the [] operator" do
    a = Neo4j::Node.new
    b = Neo4j::Node.new

    # when
    f = Friend.new(:friend, a,b)
    f[:age] = 2
    f[:colour] = 'blue'

    # then
    rel = a.rels(:friend).outgoing.first
    rel[:age].should == 2
    rel[:colour].should == 'blue'
  end

  it "can be loaded given its neo_id" do
    a = Neo4j::Node.new
    b = Neo4j::Node.new
    f = Friend.new(:friend, a,b)
    id = f.neo_id

    # when
    rel = Neo4j::Relationship.load(id)

    # then
    rel.class.should == Friend
    rel.start_node.should == a
    rel.end_node.should == b
  end

  it "can be deleted with the #del method" do
    a = Neo4j::Node.new
    b = Neo4j::Node.new
    f = Friend.new(:friend, a,b)
    id = f.neo_id
    rel = Neo4j::Relationship.load(id)

    # when
    rel.del

    # then
    Neo4j::Relationship.load(id).should be_nil
  end

  it "has an exist? method" do
    a = Neo4j::Node.new
    b = Neo4j::Node.new
    f = Friend.new(:friend, a,b)
    id = f.neo_id
    rel = Neo4j::Relationship.load(id)
    rel.should exist

    # when
    rel.del

    # then
    rel.should_not exist
  end

  it "can be specified in a NodeMixin#has_n(:type).relationship(clazz)" do
    actor = Actor.new
    movie = Movie.new
    rel = actor.acted_in.new(movie)
    rel.class.should == Role
  end

  it "friends_rels returns the relationship when declared as #has_n(:friends)" do
    actor = Actor.new
    movie = Movie.new

    # make sure we can use the << operator and
    actor.acted_in << movie
    rel = actor.acted_in_rels.first
    rel.class.should == Role
    rel.end_node.should == movie
    rel.start_node.should == actor
  end

  it "can find by using lucene" do
    a = Neo4j::Node.new
    b = Neo4j::Node.new
    f = Friend.new(:friends, a, b)
    f.since = '2000'
    finish_tx

    Friend.find('since: 2000').first.should == f
  end

  it "can not find it with lucene if it was deleted" do
    a = Neo4j::Node.new
    b = Neo4j::Node.new
    f = Friend.new(:friends, a, b)
    f.since = '2001'
    new_tx
    found = Friend.find('since: 2001').first
    found.should == f

    # when
    found.del
    finish_tx

    # then
    Friend.find('since: 2001').should be_empty
  end

  it "can not find it with indexed property was changed" do
    a = Neo4j::Node.new
    b = Neo4j::Node.new
    f = Friend.new(:friends, a, b)
    f.since = '2002'
    new_tx
    found = Friend.find('since: 2002').first
    found.should == f

    # when
    found.since = 2003
    finish_tx

    # then
    Friend.find('since: 2002').should be_empty
    Friend.find('since: 2003').first.should == found
  end

end
