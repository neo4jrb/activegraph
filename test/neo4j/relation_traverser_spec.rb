$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'spec_helper'


describe Neo4j::Relationships::RelationshipDSL do
  before(:all) do
    start
  end


  before(:each) do
    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish
  end


  

  describe 'n1.rels.outgoing(:foo) << n2' do

    it "should append n2 as outgoing node from n1" do
      n1 = Neo4j::Node.new
      n2 = Neo4j::Node.new

      # when
      n1.rels.outgoing(:foo) << n2

      # then
      n1.rels.outgoing.nodes.should include(n2)
      n2.rels.incoming.nodes.should include(n1)
    end

  end

  describe 'n1.rels.incoming(:foo) << n2' do

    it "should append n2 as incoming node to n1" do
      n1 = Neo4j::Node.new
      n2 = Neo4j::Node.new

      # when
      n1.rels.incoming(:foo) << n2

      # then
      n1.rels.incoming.nodes.should include(n2)
      n2.rels.outgoing.nodes.should include(n1)
    end

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

    it "Neo4j::rel?(:friends)==false when there are no friends" do
      t = TestNode.new
      t.rel?(:friends).should == false
    end

    it "Neo4j::rel?(:friends)==true when there are is one friend" do
      t = TestNode.new
      t1 = TestNode.new
      t.friends << t1
      t.rel?(:friends).should == true
    end

    it "Neo4j::rel?(:friends, :incoming) should return true/false if there are incoming friends" do
      t = TestNode.new
      t1 = TestNode.new
      t.friends << t1
      t.rel?(:friends, :incoming).should == false
      t1.rel?(:friends, :incoming).should == true
    end

    it "Neo4j::rel?(:friends, :incoming) should return true/false if there are incoming friends" do
      t = TestNode.new
      t1 = TestNode.new
      t.friends << t1
      t.rel?(:friends, :outgoing).should == true
      t1.rel?(:friends, :outgoing).should == false
    end

    it "Neo4j::rel should return nil when there are no rels" do
      t = TestNode.new
      t.rel(:friends, :outgoing).should be_nil
    end

    it "Neo4j::rel should return relationship when there is ONE rels" do
      t = TestNode.new
      t1 = TestNode.new
      t.friends << t1
      rel = t.rel(:friends, :outgoing)
      rel.start_node.should == t
      rel.end_node.should == t1
    end

    it "Neo4j::rel should raise an exception when there is more then ONE rels" do
      t = TestNode.new
      t.friends << TestNode.new << TestNode.new
      lambda { t.rel(:friends, :outgoing) }.should raise_error
    end

    it "should find all outgoing nodes" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t1.friends << t2

      # when
      outgoing = [*t1.rels.outgoing]
      
      # then
      outgoing.size.should == 1
      outgoing[0].should_not be_nil
      outgoing[0].end_node.should == t2
      outgoing[0].start_node.should == t1
    end
    
    it "should find all incoming nodes" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t1.friends << t2

      # when
      outgoing = [*t2.rels.incoming(:friends)]

      # then
      outgoing.size.should == 1
      outgoing[0].end_node.should == t2
      outgoing[0].start_node.should == t1
    end

    it "should find no incoming or outgoing nodes when there are none" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new

      # when and then
      [*t2.rels.incoming].size.should == 0
      [*t2.rels.outgoing].size.should == 0
    end

    it "should make sure that incoming nodes are not found in outcoming nodes" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t1.friends << t2

      # when and then
      [*t1.rels.incoming].size.should == 0
      [*t2.rels.outgoing].size.should == 0
    end


    it "should find both incoming and outgoing nodes" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t1.friends << t2

      # when and then
      [*t1.rels.both.nodes].should include(t2)
      [*t2.rels.both.nodes].should include(t1)
    end

    it "should find several both incoming and outgoing nodes" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t3 = TestNode.new
            
      t1.friends << t2
      t1.friends << t3

      # when and then
      [*t1.rels.both.nodes].should include(t2,t3)
      [*t1.rels.both.outgoing.nodes].should include(t2,t3)
      [*t2.rels.both.incoming.nodes].should include(t1)
      [*t3.rels.both.incoming.nodes].should include(t1)
      [*t1.rels.both.nodes].size.should == 2
    end
    
    it "should find incoming nodes of a specific type" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t3 = TestNode.new
            
      t1.friends << t2
      t1.friends << t3

      # when and then
      [*t1.rels.outgoing(:friends).nodes].should include(t2,t3)
      [*t2.rels.incoming(:friends).nodes].should include(t1)
      [*t3.rels.incoming(:friends).nodes].should include(t1)
    end

    it "should allow to filter rels" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t3 = TestNode.new
      t1.rels.outgoing(:foo) << t2
      t1.rels.outgoing(:foo) << t3
      t1.rels.outgoing(:foo)[t2][:colour] = 'blue'
      t1.rels.outgoing(:foo)[t3][:colour] = 'red'

      # find all relationships with property colour == blue
      [*t1.rels.outgoing.filter{self[:colour] == 'blue'}].size.should == 1
      t1.rels.outgoing.filter{self[:colour] == 'blue'}.nodes.should include(t2)
      [*t1.rels.outgoing.filter{self[:colour] == 'red'}].size.should == 1
      t1.rels.outgoing.filter{self[:colour] == 'red'}.nodes.should include(t3)
      [*t1.rels.outgoing.filter{self[:colour] == 'black'}].should be_empty
    end

  end

  
end