$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'




describe "NodeTraverser" do
  before(:all) do
    start
  end

  after(:all) do
    stop
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
      end
    end    
    
    it "should find all outgoing nodes" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t1.friends << t2

      # when
      outgoing = t1.traverse.outgoing(:friends).to_a
      
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
      t2_incoming = t2.traverse.incoming(:friends).to_a

      # then
      t2_incoming.size.should == 1
      t2_incoming[0].should == t1
    end

    it "should find no incoming or outgoing nodes when there are none" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new

      # when and then
      t2.traverse.incoming(:friends).to_a.size.should == 0
      t2.traverse.outgoing(:friends).to_a.size.should == 0
    end

    it "should make sure that incoming nodes are not found in outcoming nodes" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t1.friends << t2

      # when and then
      t1.traverse.incoming(:friends).to_a.size.should == 0
      t2.traverse.outgoing(:friends).to_a.size.should == 0
    end


    it "should find both incoming and outgoing nodes" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t1.friends << t2

      # when and then
      t1.traverse.both(:friends).to_a.should include(t2)
      t2.traverse.both(:friends).to_a.should include(t1)
    end

    it "should find several both incoming and outgoing nodes" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t3 = TestNode.new
            
      t1.friends << t2
      t1.friends << t3

      # when and then
      t1.traverse.both(:friends).to_a.should include(t2,t3)
      t1.traverse.outgoing(:friends).to_a.should include(t2,t3)
      t2.traverse.incoming(:friends).to_a.should include(t1)
      t3.traverse.incoming(:friends).to_a.should include(t1)
      t1.traverse.both(:friends).to_a.size.should == 2
    end
    
    it "should find incoming nodes of a specific type" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t3 = TestNode.new
            
      t1.friends << t2
      t1.friends << t3

      # when and then
      t1.traverse.outgoing(:friends).to_a.should include(t2,t3)
      t2.traverse.incoming(:friends).to_a.should include(t1)
      t3.traverse.incoming(:friends).to_a.should include(t1)
    end
  end


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

    it "should raise an exception if no type of direction is specified for the traversal" do
      # when and then
      lambda { @sweden.traverse.to_a }.should raise_error(Neo4j::Relations::IllegalTraversalArguments)
      lambda { @sweden.traverse.outgoing().to_a }.should raise_error(Neo4j::Relations::IllegalTraversalArguments)
    end

    it "should work with two outgoing relationship types" do
      # default is traversal of depth one
      nodes = @sweden.traverse.outgoing(:contains, :trips).to_a
      nodes.should include(@malmoe, @stockholm)
      nodes.should include(@sweden_trip)
      nodes.size.should == 3
    end

    it "should work with two incoming relationship types" do
      # in which cities are the 'The city tour specialist' available in
      nodes = @city_tour.traverse.incoming(:contains, :trips).to_a
      nodes.should include(@malmoe)
      nodes.should include(@stockholm)
      nodes.size.should == 2
    end

    it "should work with both incoming and outgoing relationship types" do
      nodes = @stockholm.traverse.incoming(:contains).outgoing(:trips).to_a
      nodes.should include(@sweden)
      nodes.should include(@city_tour)
      nodes.size.should == 2
    end

  end
  
end