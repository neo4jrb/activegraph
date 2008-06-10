require 'neo4j'
require 'spec_helper'



describe "When doing a rollback in one transaction" do
  before(:all) do start end
  after(:all)  do stop  end  

  it "should not change properties" do
    # given
    node = Neo4j::Transaction.run { Neo4j::BaseNode.new {|n| n.foo = 'foo'}  }

    # when doing a rollback
    Neo4j::Transaction.run { |t|
      node.foo = "changed"
      t.failure
    }
    
    # then
    Neo4j::Transaction.run { node.foo.should == 'foo'   }
  end
  
end



describe "When neo has been restarted" do

  def restart
    Neo4j::Neo.instance.stop
    Neo4j::Neo.instance.start 
  end
  
  
  describe Neo4j::Neo do
    before(:all) do
      start
    end

    after(:all) do
      stop
    end  
    
    
    it "should load node using its id" do
      node = Neo4j::BaseNode.new {|n|
        n.baaz = "hello"
      }
      
      restart
      
      Neo4j::Transaction.run {
        node2 = Neo4j::Neo.instance.find_node(node.neo_node_id)
        node2.baaz.should == "hello"
      }
    end
  end 
end

