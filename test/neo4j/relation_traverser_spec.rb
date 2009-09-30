$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'




describe Neo4j::Relationships::RelationshipTraverser do
  before(:all) do
    start
  end


  before(:each) do
    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish
  end


  

  describe 'n1.relationships.outgoing(:foo) << n2' do

    it "should append n2 as outgoing node from n1" do
      n1 = Neo4j::Node.new
      n2 = Neo4j::Node.new

      # when
      n1.relationships.outgoing(:foo) << n2

      # then
      n1.relationships.outgoing.nodes.should include(n2)
      n2.relationships.incoming.nodes.should include(n1)
    end

  end

  describe 'n1.relationships.incoming(:foo) << n2' do

    it "should append n2 as incoming node to n1" do
      pending "see lighthouse ticket 80, http://neo4j.lighthouseapp.com/projects/15548-neo4j/tickets/80-n1relationshipsincomingfoo-n2-does-not-work-as-expected"
      n1 = Neo4j::Node.new
      n2 = Neo4j::Node.new

      # when
      n1.relationships.incoming(:foo) << n2

      # then
      n1.relationships.incoming.nodes.should include(n2)
      n2.relationships.outgoing.nodes.should include(n1)
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

    it "Neo4j::relationship?(:friends)==false when there are no friends" do
      t = TestNode.new
      t.relationship?(:friends).should == false
    end

    it "Neo4j::relationship?(:friends)==true when there are is one friend" do
      t = TestNode.new
      t1 = TestNode.new
      t.friends << t1
      t.relationship?(:friends).should == true
    end

    it "Neo4j::relationship?(:friends, :incoming) should return true/false if there are incoming friends" do
      t = TestNode.new
      t1 = TestNode.new
      t.friends << t1
      t.relationship?(:friends, :incoming).should == false
      t1.relationship?(:friends, :incoming).should == true
    end

    it "Neo4j::relationship?(:friends, :incoming) should return true/false if there are incoming friends" do
      t = TestNode.new
      t1 = TestNode.new
      t.friends << t1
      t.relationship?(:friends, :outgoing).should == true
      t1.relationship?(:friends, :outgoing).should == false
    end

    it "Neo4j::relationship should return nil when there are no relationships" do
      t = TestNode.new
      t.relationship(:friends, :outgoing).should be_nil
    end

    it "Neo4j::relationship should return relationship when there is ONE relationships" do
      t = TestNode.new
      t1 = TestNode.new
      t.friends << t1
      rel = t.relationship(:friends, :outgoing)
      rel.start_node.should == t
      rel.end_node.should == t1
    end

    it "Neo4j::relationship should raise an exception when there is more then ONE relationships" do
      t = TestNode.new
      t.friends << TestNode.new << TestNode.new
      lambda { t.relationship(:friends, :outgoing) }.should raise_error
    end

    it "should find all outgoing nodes" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t1.friends << t2

      # when
      outgoing = t1.relationships.outgoing.to_a
      
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
      outgoing = t2.relationships.incoming.to_a

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
      t2.relationships.incoming.to_a.size.should == 0 
      t2.relationships.outgoing.to_a.size.should == 0
    end

    it "should make sure that incoming nodes are not found in outcoming nodes" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t1.friends << t2

      # when and then
      t1.relationships.incoming.to_a.size.should == 0
      t2.relationships.outgoing.to_a.size.should == 0
    end


    it "should find both incoming and outgoing nodes" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t1.friends << t2

      # when and then
      t1.relationships.both.nodes.to_a.should include(t2)
      t2.relationships.both.nodes.to_a.should include(t1)
    end

    it "should find several both incoming and outgoing nodes" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t3 = TestNode.new
            
      t1.friends << t2
      t1.friends << t3

      # when and then
      t1.relationships.both.nodes.to_a.should include(t2,t3)
      t1.relationships.both.outgoing.nodes.to_a.should include(t2,t3)
      t2.relationships.both.incoming.nodes.to_a.should include(t1)
      t3.relationships.both.incoming.nodes.to_a.should include(t1)
      t1.relationships.both.nodes.to_a.size.should == 2
    end
    
    it "should find incoming nodes of a specific type" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t3 = TestNode.new
            
      t1.friends << t2
      t1.friends << t3

      # when and then
      t1.relationships.outgoing(:friends).nodes.to_a.should include(t2,t3)
      t2.relationships.incoming(:friends).nodes.to_a.should include(t1)
      t3.relationships.incoming(:friends).nodes.to_a.should include(t1)
    end

    it "should allow to filter relationships" do
      # given
      t1 = TestNode.new
      t2 = TestNode.new
      t3 = TestNode.new
      t1.relationships.outgoing(:foo) << t2
      t1.relationships.outgoing(:foo) << t3
      t1.relationships.outgoing(:foo)[t2][:colour] = 'blue'
      t1.relationships.outgoing(:foo)[t3][:colour] = 'red'

      # find all relationships with property colour == blue
      t1.relationships.outgoing.filter{self[:colour] == 'blue'}.to_a.size.should == 1
      t1.relationships.outgoing.filter{self[:colour] == 'blue'}.nodes.should include(t2)
      t1.relationships.outgoing.filter{self[:colour] == 'red'}.to_a.size.should == 1
      t1.relationships.outgoing.filter{self[:colour] == 'red'}.nodes.should include(t3)
      t1.relationships.outgoing.filter{self[:colour] == 'black'}.to_a.should be_empty
    end

  end

  
end