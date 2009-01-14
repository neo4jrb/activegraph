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
        has_n :companies
        property :name
        index :name
      end

      # A company can exist in one or more locations
      # A company can be local for a sub location (like a city) or global for a whole region (ie. europe).
      class Company
        include Neo4j::NodeMixin
        property :name
      end
    end

    it "should return both types of Nodes when traversing two relationship types" do
      pending
      europe = Location.new{|n| n.name = 'europe'}
      sweden = Location.new{|n| n.name = 'sweden'}
      denmark = Location.new{|n| n.name = 'denmark'}
      elmhult = Location.new{|n| n.name = 'elmhult'}
      europe.contains << sweden << denmark
      sweden.contains << elmhult

      ikea = Company.new{|n| n.name = 'ikea'}
      elmhult.companies << ikea

      carlsberg = Company.new{|n| n.name = 'ikea'}
      denmark.companies << carlsberg
      
      nodes = sweden.traverse.outgoing(:contains, :companies).to_a
      nodes.should include(europe, sweden, denmark)
      nodes.should include(ikea, carlsberg)
    end

#    it "should return both types of Nodes when traversing two relationship types" do
#      europe = Location.new{|n| n.name = 'europe'}
#      sweden = Location.new{|n| n.name = 'sweden'}
#      denmark = Location.new{|n| n.name = 'denmark'}
#      elmhult = Location.new{|n| n.name = 'elmhult'}
#      europe.contains << sweden << denmark
#      sweden.contains << elmhult
#
#      ikea = Company.new{|n| n.name = 'ikea'}
#      elmhult.companies << ikea
#
#      carlsberg = Company.new{|n| n.name = 'ikea'}
#      denmark.companies << carlsberg
#
#      sweden.traverse.outgoing(:contains, :companies)
#    end

  end
  
end