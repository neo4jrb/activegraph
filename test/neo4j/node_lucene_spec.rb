require 'neo4j'
require 'neo4j/spec_helper'


  
  
describe "Neo4j & Lucene Transaction Synchronization:" do
  before(:all) do
    start
    class TestNode 
      include Neo4j::Node
      properties :name, :age
    end
  end
  after(:all) do
    stop
  end  
    
  it "should not update the index if the transaction rollsback" do
    # given
    n1 = nil
    Neo4j::Transaction.run do |t|
      n1 = TestNode.new
      n1.name = 'hello'
        
      # when
      t.failure  
    end
      
    # then
    n1.should_not be_nil
    TestNode.find(:name => 'hello').should_not include(n1)
  end
    
  it "should reindex when a property has been changed" do
    # given
    n1 = TestNode.new
    n1.name = 'hi'
      
    TestNode.find(:name => 'hi').should include(n1)
      
      
    # when
    n1.name = "oj"
      
    # then
    TestNode.find(:name => 'hi').should_not include(n1)
    TestNode.find(:name => 'oj').should include(n1)      
  end
    
  it "should remove the index when a node has been deleted" do
    # given
    n1 = TestNode.new
    n1.name = 'remove'

    # make sure we can find it
    TestNode.find(:name => 'remove').should include(n1)            
      
    # when
    n1.delete
      
    # then
    TestNode.find(:name => 'remove').should_not include(n1)
  end
end
  
  
describe "Find Nodes using Lucene" do
  before(:all) do
    start
    class TestNode 
      include Neo4j::Node
      properties :name, :age, :male, :height
    end
    @foos = []
    5.times {|n|
      node = TestNode.new
      node.name = "foo#{n}"
      node.age = n # "#{n}"
      node.male = (n == 0)
      node.height = n * 0.1
      @foos << node
    }
    @bars = []
    5.times {|n|
      node = TestNode.new
      node.name = "bar#{n}"
      node.age = n # "#{n}"
      node.male = (n == 0) 
      node.height = n * 0.1        
      @bars << node
    }
  end
    
  after(:all) do
    stop
  end  
  
  it "should find one node" do
    found = TestNode.find(:name => 'foo2')
    found[0].name.should == 'foo2'
    found.should include(@foos[2])
    found.size.should == 1
  end

  it "should find two nodes" do
    found = TestNode.find(:age => 0)
    found.should include(@foos[0])
    found.should include(@bars[0])      
    found.size.should == 2
  end

  it "should find using two fields" do
    found = TestNode.find(:age => 0, :name => 'foo0')
    found.should include(@foos[0])
    found.size.should == 1
  end
    
  it "should find using a boolean property query" do
    found = TestNode.find(:male => true)
    found.should include(@foos[0], @bars[0])
    found.size.should == 2
  end
    
  it "should find using a float property query" do
    found = TestNode.find(:height => 0.2)
    found.should include(@foos[2], @bars[2])
    found.size.should == 2
  end
    
end
