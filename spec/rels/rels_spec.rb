require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::Node, :type => :transactional do

  def create_nodes
    #
    #                f
    #                ^
    #              friends
    #                |
    #  a --friends-> b  --friends--> c
    #                |              ^
    #                |              |
    #                +--- work  -----+
    #                |
    #                +--- work  ---> d  --- work --> e
    a = Neo4j::Node.new :name => 'a'
    b = Neo4j::Node.new :name => 'b'
    c = Neo4j::Node.new :name => 'c'
    d = Neo4j::Node.new :name => 'd'
    e = Neo4j::Node.new :name => 'e'
    f = Neo4j::Node.new :name => 'f'
    a.outgoing(:friends) << b
    b.outgoing(:friends) << c
    b.outgoing(:work) << c
    b.outgoing(:work) << d
    d.outgoing(:work) << e
    b.outgoing(:friends) << f
    [a, b, c, d, e, f]
  end


  describe "#node(direction, type)"do
    before(:each) do
      @a,@b,@c,@d,@e,@f = create_nodes #Neo4j::Transaction.run {create_nodes}
    end

    it "returns a node of the given relationship type if it exists" do
      @a.node(:outgoing, :friends).should == @b
    end

    it "returns nil if the given relationship does not exist" do
      @a.node(:incoming, :friends).should be_nil
      @a.node(:outgoing, :unknown_rel).should be_nil
    end

    it "should raise an exception if there are more then one relationship" do
      lambda {@b.node(:work)}.should raise_exception
    end
  end

  it "#rel? returns true if there are any relationship" do
    a = Neo4j::Node.new
    a.rel?.should be_false
    a.outgoing(:foo) << Neo4j::Node.new
    a.rel?.should be_true
    a.rel?(:bar).should be_false
    a.rel?(:foo).should be_true
    a.rel?(:foo, :incoming).should be_false
    a.rel?(:foo, :outgoing).should be_true
  end
  
  it "#rels should return both incoming and outgoing relationship of any type of depth one" do
    a, b, c, d, e, f = create_nodes
    b.rels.size.should == 5
    nodes = b.rels.collect { |r| r.other_node(b) }
    nodes.should include(a, c, d, f)
    nodes.should_not include(e)
  end

  it "#_rels returns unwrapped nodes" do
    a, b, c, d, e, f = create_nodes
    b._rels.to_a.size.should == 5
    nodes = b._rels.collect { |r| r._other_node(b) }
    nodes.should include(a, c, d, f)
    nodes.should_not include(e)
  end

  it "#_rels(:type1, :type2) returns unwrapped nodes" do
    a, b, c, d, e, f = create_nodes
    b._rels(:both, :friends, :work).to_a.size.should == 5
    nodes = b._rels.collect { |r| r._other_node(b) }
    nodes.should include(a, c, d, f)
    nodes.should_not include(e)
  end

  it "#_rels(:type1) returns unwrapped nodes" do
    a, b, c, d, e, f = create_nodes
    b._rels(:both, :work).to_a.size.should == 2
    nodes = b._rels.collect { |r| r._other_node(b) }
    nodes.should include(c, d)
  end

  it "#:rels with illegal args should raise" do
    a, b, c, d, e, f = create_nodes
    lambda{b._rels(:incoming)}.should raise_exception
  end

  it "#rels(:friends) should return both incoming and outgoing relationships of given type of depth one" do
    # given
    a, b, c, d, e, f = create_nodes

    # when
    rels = [*b.rels(:friends)]

    # then
    rels.size.should == 3
    nodes = rels.collect { |r| r.end_node }
    nodes.should include(b, c, f)
    nodes.should_not include(a, d, e)
  end

  it "#rels(:friends).outgoing should return only outgoing relationships of given type of depth one" do
    # given
    a, b, c, d, e, f = create_nodes

    # when
    rels = [*b.rels(:friends).outgoing]

    # then
    rels.size.should == 2
    nodes = rels.collect { |r| r.end_node }
    nodes.should include(c, f)
    nodes.should_not include(a, b, d, e)
  end


  it "#rels(:friends).incoming should return only outgoing relationships of given type of depth one" do
    # given
    a, b, c, d, e = create_nodes

    # when
    rels = [*b.rels(:friends).incoming]

    # then
    rels.size.should == 1
    nodes = rels.collect { |r| r.start_node }
    nodes.should include(a)
    nodes.should_not include(b, c, d, e)
  end

  it "#rels(:friends,:work) should return both incoming and outgoing relationships of given types of depth one" do
    # given
    a, b, c, d, e, f = create_nodes

    # when
    rels = [*b.rels(:friends, :work)]

    # then
    rels.size.should == 5
    nodes = rels.collect { |r| r.other_node(b) }
    nodes.should include(a, c, d, f)
    nodes.should_not include(b, e)
  end

  it "#rels(:friends,:work).outgoing/incoming should raise exception" do
    node = Neo4j::Node.new
    expect { node.rels(:friends, :work).outgoing }.to raise_error
    expect { node.rels(:friends, :work).incoming }.to raise_error
  end

  it "#rel returns a single relationship if there is only one relationship" do
    a = Neo4j::Node.new
    b = Neo4j::Node.new
    rel = Neo4j::Relationship.new(:friend, a, b)
    a.rel(:outgoing, :friend).should == rel
  end

  it "#rel returns nil if there is no relationship" do
    a = Neo4j::Node.new
    b = Neo4j::Node.new
    a.rel(:outgoing, :friend).should be_nil
  end

  it "#rel should raise an exception if there are more then one relationship" do
    a = Neo4j::Node.new
    b = Neo4j::Node.new
    c = Neo4j::Node.new
    Neo4j::Relationship.new(:friend, a, b)
    Neo4j::Relationship.new(:friend, a, c)
    expect { a.rel(:outgoing, :friend) }.to raise_error
  end

  it "#rels returns a Traverser which can filter which relationship it should return by specifying #to_other" do
    a = Neo4j::Node.new
    b = Neo4j::Node.new
    c = Neo4j::Node.new
    r1 = Neo4j::Relationship.new(:friend, a, b)
    Neo4j::Relationship.new(:friend, a, c)

    a.rels.to_other(b).size.should == 1
    a.rels.to_other(b).should include(r1)
  end

  it "#rels returns an Traverser which provides a method for deleting all the relationships" do
    a = Neo4j::Node.new
    b = Neo4j::Node.new
    c = Neo4j::Node.new
    r1 = Neo4j::Relationship.new(:friend, a, b)
    r2 = Neo4j::Relationship.new(:friend, a, c)

    a.rel?(:friend).should be_true
    a.rels.del
    a.rel?(:friend).should be_false
    new_tx
    r1.exist?.should be_false
    r2.exist?.should be_false
  end

  it "#rels returns an Traverser with methods #del and #to_other which can be combined to only delete a subset of the relationships" do
    a = Neo4j::Node.new
    b = Neo4j::Node.new
    c = Neo4j::Node.new
    r1 = Neo4j::Relationship.new(:friend, a, b)
    r2 = Neo4j::Relationship.new(:friend, a, c)
    r1.exist?.should be_true
    r2.exist?.should be_true

    a.rels.to_other(c).del
    new_tx
    r1.exist?.should be_true
    r2.exist?.should be_false
  end
end
