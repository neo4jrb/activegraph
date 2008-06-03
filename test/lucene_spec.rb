require 'neo4j'
require 'spec_helper'
require 'pp'

# specs for Neo4j::Neo


# ------------------------------------------------------------------------------
# the following specs are run inside one Neo4j transaction
# 

describe "When running in one transaction" do
  before(:all) do
    start
    @transaction = Neo4j::Transaction.new
    @transaction.start
  end

  after(:all) do
    remove_class_defs     # so that we can define the same class again        
    @transaction.failure # do not want to store anything
    @transaction.finish
    stop
  end  
  
  
  describe "simple search" do
    before(:all) do
      class TestNode 
        include Neo4j::Node
        properties :name, :age
      end
      @foos = []
      5.times {|n|
        node = TestNode.new
        node.name = "foo#{n}"
        node.age = "#{n}"
        @foos << node
      }
      @bars = []
      5.times {|n|
        node = TestNode.new
        node.name = "bar#{n}"
        node.age = "#{n}"
        @bars << node
      }
      
    end
    
    it "should find one node" do
      found = TestNode.find(:name => 'foo2')
      found[0].name.should == 'foo2'
      found.should include(@foos[2])
      found.size.should == 1
    end

    it "should find two nodes" do
      found = TestNode.find(:age => '0')
      found.should include(@foos[0])
      found.should include(@bars[0])      
      found.size.should == 2
    end

    it "should find using two fields" do
      found = TestNode.find(:age => '0', :name => 'foo0')
      found.should include(@foos[0])
      found.size.should == 1
    end
    
  end
end