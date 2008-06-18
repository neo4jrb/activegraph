require 'neo4j'
require 'neo4j/spec_helper'





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
    @transaction.failure # do not want to store anything
    @transaction.finish
    stop
  end  
  
  
  
  describe "When creating a relationship" do
    before(:all) do
      class TestNode 
        include Neo4j::Node
      
        relations :friends
      end
    end
    
    it "should allow to set properties on it" do
      t1 = TestNode.new
      t2 = TestNode.new
      
      r = t1.friends.new(t2)
      
      r.friend_since = 1992
      
      r.friend_since.should == 1992
    end
  end
  
end