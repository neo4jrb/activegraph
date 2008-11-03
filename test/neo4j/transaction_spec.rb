require 'neo4j'
require 'neo4j/spec_helper'


class BaseNode
  include Neo4j::NodeMixin
  include Neo4j::DynamicAccessorMixin
end


describe "transaction rollback" do
  before(:all) do start end
  after(:all)  do stop  end  

  it "should not change properties" do
    # given
    #$NEO_LOGGER.level = Logger::DEBUG

    node = Neo4j::Transaction.run { BaseNode.new {|n| n.foo = 'foo'} }

    #   $NEO_LOGGER.level = Logger::WARN
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
    Neo4j.stop
    Neo4j.start NEO_STORAGE, LUCENE_INDEX_LOCATION
  end
  
  
  describe Neo4j::Neo do
    before(:all) do
      start
    end

    after(:all) do
      stop
    end  
    
    
    it "should load node using its id" do
      node = BaseNode.new {|n|
        n.baaz = "hello"
      }
      
      restart
      
      Neo4j::Transaction.run {
        node2 = Neo4j.instance.find_node(node.neo_node_id)
        node2.baaz.should == "hello"
      }
    end
  end 
end

