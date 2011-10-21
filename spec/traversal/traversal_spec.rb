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

  describe "#outgoing(:friends).paths" do
    it "returns paths objects" do
      a,* = create_nodes
      paths = a.outgoing(:friends).outgoing(:work).depth(:all).paths.to_a
      paths.each {|x| x.should be_kind_of(org.neo4j.graphdb.Path)}
      paths.size.should == 5
    end
  end

  describe "#outgoing(:friends).rels" do
    it "returns paths objects" do
      a,* = create_nodes
      paths = a.outgoing(:friends).outgoing(:work).depth(:all).rels.to_a
      paths.each {|x| x.should be_kind_of(org.neo4j.graphdb.Relationship)}
      paths.size.should == 5
    end
  end

  describe "#raw" do
    before(:all) do
      new_tx
      @node = SimpleNode.new
      @node.outgoing(:simple) << SimpleNode.new << SimpleNode.new
      finish_tx
    end
    it "does not return the wrapper instances" do
      @node.outgoing(:simple).size.should == 2
      @node.outgoing(:simple).raw.each {|n| n.class.should == Neo4j::Node}
    end

    it "does return the wrapper instances when not using raw" do
      @node.outgoing(:simple).each {|n| n.class.should == SimpleNode}
    end

  end

  it "#outgoing(:friends) << other_node creates an outgoing relationship of type :friends" do
    a = Neo4j::Node.new
    other_node = Neo4j::Node.new

    # when
    a.outgoing(:friends) << other_node

    # then
    a.outgoing(:friends).first.should == other_node
  end

  it "#outgoing(:friends) << b << c creates an outgoing relationship of type :friends" do
    a = Neo4j::Node.new
    b = Neo4j::Node.new
    c = Neo4j::Node.new

    # when
    a.outgoing(:friends) << b << c

    # then
    a.outgoing(:friends).should include(b, c)
  end

  it "#incoming(:friends) << other_node should add an incoming relationship" do
    a = Neo4j::Node.new
    other_node = Neo4j::Node.new

    # when
    a.incoming(:friends) << other_node

    # then
    a.incoming(:friends).first.should == other_node
  end

  it "#both(:friends) << other_node should raise an exception" do
    a = Neo4j::Node.new
    other_node = Neo4j::Node.new

    # when
    expect { a.both(:friends) << other_node }.to raise_error
  end

  it "#both returns all outgoing nodes of any type" do
    a, b, c, d, e, f = create_nodes
    b.both.should include(a, c, d, f)
    [*b.both].size.should == 4
  end

  it "#incoming returns all incoming nodes of any type" do
    pending
    a, b, c, d = create_nodes
    #b.incoming.should include(...)
    #[*b.incoming].size.should == .
  end

  it "#outgoing returns all outgoing nodes of any type" do
    pending
    a, b, c, d = create_nodes
    #b.outgoing.should include()
    #[*b.outgoing].size.should == ..
  end

  it "#outgoing(type) should only return outgoing nodes of the given type of depth one" do
    a, b, c, d = create_nodes
    b.outgoing(:work).should include(c, d)
    [*b.outgoing(:work)].size.should == 2
  end

  it "#outgoing(type1).outgoing(type2) should return outgoing nodes of the given types" do
    a, b, c, d, e, f = create_nodes
    nodes = b.outgoing(:work).outgoing(:friends)
    nodes.should include(c, d, f)
    nodes.size.should == 3
  end

  it "#outgoing(type).depth(4) should only return outgoing nodes of the given type and depth" do
    a, b, c, d, e = create_nodes
    [*b.outgoing(:work).depth(4)].size.should == 3
    b.outgoing(:work).depth(4).should include(c, d, e)
  end

  it "#outgoing(type).depth(4).include_start_node should also include the start node" do
    a, b, c, d, e = create_nodes
    [*b.outgoing(:work).depth(4).include_start_node].size.should == 4
    b.outgoing(:work).depth(4).include_start_node.should include(b, c, d, e)
  end

  it "#outgoing(type).depth(:all) should traverse at any depth" do
    a, b, c, d, e = create_nodes
    [*b.outgoing(:work).depth(:all)].size.should == 3
    b.outgoing(:work).depth(:all).should include(c, d, e)
  end

  it "#incoming(type).depth(2) should only return outgoing nodes of the given type and depth" do
    a, b, c, d, e = create_nodes
    [*e.incoming(:work).depth(2)].size.should == 2
    e.incoming(:work).depth(2).should include(b, d)
  end


  it "#incoming(type) should only return incoming nodes of the given type of depth one" do
    a, b, c, d = create_nodes
    c.incoming(:work).should include(b)
    [*c.incoming(:work)].size.should == 1
  end

  it "#both(type) should return both incoming and outgoing nodes of the given type of depth one" do
    a, b, c, d, e, f = create_nodes
#      [a,b,c,d].each_with_index {|n,i| puts "#{i} : id #{n.id}"}
    b.both(:friends).should include(a, c, f)
    [*b.both(:friends)].size.should == 3
  end

  it "#outgoing and #incoming can be combined to traverse several relationship types" do
    a, b, c, d, e = create_nodes
    nodes = [*b.incoming(:friends).outgoing(:work)]
    nodes.should include(a, c, d)
    nodes.should_not include(b, e)
  end


  it "#prune takes a block with parameter of type Java::org.neo4j.graphdb.Path" do
    a, b, c, d, e = create_nodes
    b.outgoing(:friends).depth(4).prune { |path| path.should be_kind_of(Java::org.neo4j.graphdb.Path); false }.each {}
  end

  it "#prune, if it returns true the traversal will be 'cut off' that path" do
    a, b, c, d, e = create_nodes

    [*b.outgoing(:work).depth(4).prune { |path| true }].size.should == 2
    b.outgoing(:work).depth(4).prune { |path| true }.should include(c, d)
  end

  it "#filter takes a block with parameter of type Java::org.neo4j.graphdb.Path" do
    a, b, c, d, e = create_nodes
    b.outgoing(:friends).depth(4).filter { |path| path.should be_kind_of(Java::org.neo4j.graphdb.Path); false }.each {}
  end

  it "#filter takes a block with parameter of type Java::org.neo4j.graphdb.Path" do
    a, b, c, d, e = create_nodes
    nodes = [*b.outgoing(:work).depth(4).filter { |path| path.length == 2 }]
    nodes.size.should == 1
    nodes.should include(e)
  end

  it "#filter accept several filters which all must return true in order to include the node in the traversal result" do
    a, b, c, d, e = create_nodes
    nodes = [*b.outgoing(:work).depth(4).filter { |path| %w[c d].include?(path.end_node[:name]) }.
        filter { |path| %w[d e].include?(path.end_node[:name]) }]
    nodes.should include(d)
    nodes.should_not include(e)
    nodes.size.should == 1
  end

  describe "#expand" do

    before(:each) do
      new_tx
      @x = Neo4j::Node.new :name => 'x'
      @a = Neo4j::Node.new :name => 'a'
      @b = Neo4j::Node.new :name => 'b'
      @c = Neo4j::Node.new :name => 'c'
      @d = Neo4j::Node.new :name => 'd'
      @e = Neo4j::Node.new :name => 'e'
      @f = Neo4j::Node.new :name => 'f'
      @y = Neo4j::Node.new :name => 'y'
    end

    it "can be used to select relationships based on relationship properties" do
      Neo4j::Relationship.new(:friends, @x, @a, :age => 1)
      Neo4j::Relationship.new(:friends, @x, @b, :age => 10)
      Neo4j::Relationship.new(:friends, @b, @c, :age => 1)
      Neo4j::Relationship.new(:friends, @b, @d, :age => 10)

      res = @x.expand { |n| n._rels.find_all { |r| r[:age] > 5 } }.depth(:all).to_a
      res.should include(@b, @d)
      res.size.should == 2
    end

    it "default is depth(1) traversals" do
      Neo4j::Relationship.new(:friends, @x, @a, :age => 1)
      Neo4j::Relationship.new(:friends, @x, @b, :age => 10)
      Neo4j::Relationship.new(:friends, @b, @c, :age => 1)
      Neo4j::Relationship.new(:friends, @b, @d, :age => 10)

      res = @x.expand { |n| n._rels.find_all { |r| r[:age] > 5 } }.to_a
      res.should include(@b)
      res.size.should == 1
    end

    it "returns nothing when expand returns an empty array" do
      Neo4j::Relationship.new(:friends, @x, @a)
      Neo4j::Relationship.new(:friends, @x, @b)
      Neo4j::Relationship.new(:friends, @b, @c)
      Neo4j::Relationship.new(:friends, @b, @d)
      res = @x.expand { |*| [] }.depth(:all)
      res.should be_empty
    end

  end

  describe "Neo4j::Node#eval_paths", :type => :transactional do
    before(:all) do
      new_tx
      @principal1 = Neo4j::Node.new(:name => 'principal1')
      @principal2 = Neo4j::Node.new(:name => 'principal2')
      @pet0 = Neo4j::Node.new(:name => 'pet0')
      @pet1 = Neo4j::Node.new(:name => 'pet1')
      @pet2 = Neo4j::Node.new(:name => 'pet2')
      @pet3 = Neo4j::Node.new(:name => 'pet3')

      @principal1.outgoing(:owns) << @pet1 << @pet3
      @pet0.outgoing(:descendant) << @pet1 << @pet2 << @pet3
      @principal2.outgoing(:owns) << @pet2
      finish_tx
    end

    it "#unique :node_path returns paths that is traversed more then once" do
      result = @pet0.eval_paths {|path| path.end_node ==  @principal1 ? :include_and_prune : :exclude_and_continue }.unique(:node_path).depth(:all).to_a
      result.size.should == 2
      result.should include(@principal1)
    end

    it "#unique :node_global returns paths that is traversed more then once" do
      result = @pet0.eval_paths {|path| path.end_node ==  @principal1 ? :include_and_prune : :exclude_and_continue }.unique(:node_global).depth(:all).to_a
      result.size.should == 1
      result.should include(@principal1)
    end

  end

end
