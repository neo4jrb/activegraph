$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'spec_helper'




describe "NodeTraverser" do
  before(:all) do
    start
  end

  before(:each) do
    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish
  end



  # ----------------------------------------------------------------------------
  #  traversing outgoing and incoming nodes
  #

  describe 'traversing outgoing and incoming nodes' do
    before(:all) do
      undefine_class :TestNode  # make sure it is not already defined

      class TestNode
        include Neo4j::NodeMixin
        has_n :friends
        has_n :parents
        property :name
      end
    end

    it "should find all outgoing nodes" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t1.friends << t2

      t1.traverse.outgoing(:friends)

      # when
      outgoing = [*t1.traverse.outgoing(:friends)]

      # then
      outgoing.size.should == 1
      outgoing[0].should == t2
    end

    it "should find all incoming nodes" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t1.friends << t2

      # when
      t2_incoming = [*t2.traverse.incoming(:friends)]

      # then
      t2_incoming.size.should == 1
      t2_incoming[0].should == t1
    end

    it "should find no incoming or outgoing nodes when there are none" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new

      # when and then
      [*t2.traverse.incoming(:friends)].size.should == 0
      [*t2.traverse.outgoing(:friends)].size.should == 0
    end

    it "should make sure that incoming nodes are not found in outcoming nodes" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t1.friends << t2

      # when and then
      [*t1.traverse.incoming(:friends)].size.should == 0
      [*t2.traverse.outgoing(:friends)].size.should == 0
    end


    it "should find both incoming and outgoing nodes" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t1.friends << t2

      # when and then
      [*t1.traverse.both(:friends)].should include(t2)
      [*t2.traverse.both(:friends)].should include(t1)
    end

    it "should find several both incoming and outgoing nodes" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t3 = TestNode.new

      t1.friends << t2
      t1.friends << t3

      # when and then
      [*t1.traverse.both(:friends)].should include(t2, t3)
      [*t1.traverse.outgoing(:friends)].should include(t2, t3)
      [*t2.traverse.incoming(:friends)].should include(t1)
      [*t3.traverse.incoming(:friends)].should include(t1)
      [*t1.traverse.both(:friends)].size.should == 2
    end

    it "should find incoming nodes of a specific type" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t3 = TestNode.new

      t1.friends << t2
      t1.friends << t3

      # when and then
      [*t1.traverse.outgoing(:friends)].should include(t2, t3)
      [*t2.traverse.incoming(:friends)].should include(t1)
      [*t3.traverse.incoming(:friends)].should include(t1)
    end

    it "should find outgoing nodes of depth 2" do
      # given
      t = TestNode.new
      t1 = TestNode.new
      t11 = TestNode.new
      t111 = TestNode.new
      t12 = TestNode.new
      t2 = TestNode.new

      t.friends << t1 << t2
      t1.friends << t12 << t11
      t11.friends << t111

      # when and then
      t1_outgoing = [*t1.traverse.outgoing(:friends).depth(2)]
      t1_outgoing.size.should == 3
      t1_outgoing.should include(t11, t111, t12)
    end

    it "should find outgoing nodes of depth all" do
      # given
      t = TestNode.new
      t1 = TestNode.new
      t11 = TestNode.new
      t111 = TestNode.new
      t12 = TestNode.new
      t2 = TestNode.new

      t.friends << t1 << t2
      t1.friends << t12 << t11
      t11.friends << t111

      # when and then
      t_outgoing = [*t.traverse.outgoing(:friends).depth(:all)]
      t_outgoing.size.should == 5
      t_outgoing.should include(t1, t11, t111, t12, t2)
    end

    it "should find incoming nodes of depth 2" do
      # given
      t = TestNode.new
      t1 = TestNode.new
      t11 = TestNode.new
      t111 = TestNode.new
      t12 = TestNode.new
      t2 = TestNode.new

      t.friends << t1 << t2
      t1.friends << t12 << t11
      t11.friends << t111

      # when and then
      t11_incoming = [*t11.traverse.incoming(:friends).depth(2)]
      t11_incoming.size.should == 2
      t11_incoming.should include(t, t1)
    end

    it "should find outgoing nodes using a filter function that will be evaluated in the context of the current node" do
      # given
      a = TestNode.new
      b = TestNode.new
      c = TestNode.new
      a.name = "a"
      b.name = "b"
      c.name = "c"
      a.friends << b << c

      # when
      result = [*a.traverse.outgoing(:friends).filter{ name == 'b'}]

      # then
      result.size.should == 1
      result.should include(b)
    end

  end


  # ----------------------------------------------------------------------------
  #  traversing using the TraversalPostion information
  #

  describe 'traversing using the TraversalPostion information' do
    before(:all) do
      undefine_class :TestNode  # make sure it is not already defined

      class TestNode
        include Neo4j::NodeMixin
        has_n :friends
        has_n :parents
        property :name
      end

      Neo4j::Transaction.run do
        # given
        @a = TestNode.new
        @b = TestNode.new
        @c = TestNode.new
        @p = TestNode.new
        @a.name = 'a'
        @b.name = 'b'
        @c.name = 'c'
        @p.name = 'p'
        @a.friends << @b << @c
        @a.parents << @p
      end
    end

    it "should work with the TraversalPosition#current_node parameter for filter" do
      # when
      result = [*@a.traverse.outgoing(:friends).filter{|tp| tp.current_node.name == 'b'}]

      # then
      result.size.should == 1
      result.should include(@b)
    end

    it "should work with the TraversalPosition#previous_node parameter for filter" do
      # when
      result = [*@a.traverse.outgoing(:friends).filter{|tp| tp.previous_node.name == 'a' unless tp.previous_node.nil?}]

      # then
      result.size.should == 2
      result.should include(@b, @c)
    end

    it "should work with the TraversalPosition#last_relationship_traversed parameter  for filter" do
      # when
      result = [*@a.traverse.outgoing(:friends, :parents).filter do |tp|
        tp.last_relationship_traversed.relationship_type == :parents unless tp.last_relationship_traversed.nil?
      end]

      # then
      result.size.should == 1
      result.should include(@p)
    end

    it "should work with the TraversalPosition#depth parameter  for filter" do
      # when
      result = [*@a.traverse.outgoing(:friends, :parents).filter { |tp|  tp.depth == 0 }]

      # then
      result.size.should == 1
      result.should include(@a)
    end

    it "should work with the TraversalPosition#returned_nodes_count parameter for filter" do
      # when
      result = [*@a.traverse.outgoing(:friends, :parents).filter { |tp|  tp.returned_nodes_count < 2 }]

      # then
      result.size.should == 2
    end


    it "should work with the TraversalPosition parameter for each_with_position" do
      # when
      a = Neo4j::Node.new; a[:name] = 'a'
      b = Neo4j::Node.new; b[:name] = 'b'
      c = Neo4j::Node.new; c[:name] = 'c'
      d = Neo4j::Node.new; d[:name] = 'd'
      a.rels.outgoing(:baar) << b
      a.rels.outgoing(:baar) << c
      b.rels.outgoing(:baar) << d

      name_depth = {}
      a.outgoing(:baar).depth(:all).each_with_position { |node, tp| name_depth[node[:name]] = tp.depth }

     # then
      name_depth['b'].should == 1
      name_depth['c'].should == 1
      name_depth['d'].should == 2
    end

  end

  # ----------------------------------------------------------------------------
  #  traversing several relationships at the same time
  #

  describe "traversing several relationships at the same time" do
    before(:all) do
      # A location contains a hierarchy of other locations
      # Example region (asia) contains countries which contains  cities etc...
      class Location
        include Neo4j::NodeMixin
        has_n :contains
        has_n :trips
        property :name
        index :name

        def self.create(name)
          location = Location.new
          location.name = name
          location
        end
      end

      # A Trip can be specific for one global area, such as "see all of sweden" or
      # local such as a 'city tour of malmoe'
      class Trip
        include Neo4j::NodeMixin
        property :name

        def self.create(name)
          trip = Trip.new
          trip.name = name
          trip
        end

      end

      Neo4j::Transaction.run do
        @europe = Location.create 'europe'
        @sweden = Location.create 'sweden'
        @denmark = Location.create 'denmark'
        @malmoe = Location.create 'malmoe'
        @stockholm = Location.create 'stockholm'
        @europe.contains << @sweden << @denmark
        @sweden.contains << @malmoe << @stockholm

        @sweden_trip = Trip.create 'See all of sweden in 14 days'
        @city_tour = Trip.create 'The city tour specialist'
        @malmoe_trip = Trip.create 'Malmoe city sightseeing by boat'

        @sweden.trips << @sweden_trip
        @malmoe.trips << @malmoe_trip
        @malmoe.trips << @city_tour
        @stockholm.trips << @city_tour # the same city tour is available both in malmoe and stockholm
      end

    end

    it "should raise an exception if no type of direction is specified for the traversal" do
      # when and then
      lambda { [*@sweden.traverse] }.should raise_error(Neo4j::Relationships::IllegalTraversalArguments)
      lambda { [*@sweden.traverse.outgoing()] }.should raise_error(Neo4j::Relationships::IllegalTraversalArguments)
    end

    it "should work with two outgoing relationship types" do
      # default is traversal of depth one
      nodes = [*@sweden.traverse.outgoing(:contains, :trips)]
      nodes.should include(@malmoe, @stockholm)
      nodes.should include(@sweden_trip)
      nodes.size.should == 3
    end

    it "should work with two incoming relationship types" do
      # in which cities are the 'The city tour specialist' available in
      nodes = [*@city_tour.traverse.incoming(:contains, :trips)]
      nodes.should include(@malmoe)
      nodes.should include(@stockholm)
      nodes.size.should == 2
    end

    it "should work with two outgoing relationship types and a filter" do
      # find all trips in sweden
      nodes = [*@sweden.traverse.outgoing(:contains, :trips).depth(:all).filter do |tp|
        tp.last_relationship_traversed.relationship_type == :trips unless tp.last_relationship_traversed.nil?
      end]

      nodes.should include(@sweden_trip)
      nodes.should include(@city_tour)
      nodes.should include(@malmoe_trip)
      nodes.size.should == 3
    end

    it "should work with both incoming and outgoing relationship types" do
      nodes = [*@stockholm.traverse.incoming(:contains).outgoing(:trips)]
      nodes.should include(@sweden)
      nodes.should include(@city_tour)
      nodes.size.should == 2
    end

  end

end