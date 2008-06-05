require 'neo4j'
require 'spec_helper'
require 'pp'

# specs for Neo4j::Neo


# ------------------------------------------------------------------------------
# the following specs are run inside one Neo4j transaction
# 

describe "Lucene Queries" do
  before(:all) do
    start
  end

  after(:all) do
    remove_class_defs     # so that we can define the same class again        
    stop
  end  
  
  
  describe Neo4j::LuceneTransaction, "when rollback a transaction" do
    before(:all) do
      class Test2Node 
        include Neo4j::Node
        properties :name, :age
      end
    end
    
    it "should reindex it" do
      # given
      n1 = Neo4j::Transaction.run do |t|
        n1 = Test2Node.new
        n1.name = 'hello'
        
        # when
        t.failure  
        n1
      end
      
      # then
      Neo4j::Transaction.run do
        Test2Node.find(:name => 'hello').should_not include(n1)
      end
    end    
  end
  
  describe Neo4j::LuceneTransaction, "when changing properties" do
    before(:all) do
      class TestNode2 
        include Neo4j::Node
        properties :name, :age
      end
    end
    
    it "should reindex it" do
      # given
      n1 = TestNode2.new
      n1.name = 'hi'
      n1
      
      TestNode2.find(:name => 'hi').should include(n1)
      
      
      # when
      n1.name = "oj"
      
      # then
      TestNode2.find(:name => 'hi').should_not include(n1)
      TestNode2.find(:name => 'oj').should include(n1)      
    end
  end
  
  
  describe Neo4j::LuceneQuery, "(simple search)" do
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