$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

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
    node = Neo4j::Transaction.run { BaseNode.new {|n| n.foo = 'foo'} }

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
      
      Neo4j.stop
      Neo4j.start
      
      Neo4j::Transaction.run {
        node2 = Neo4j.instance.find_node(node.neo_node_id)
        node2.baaz.should == "hello"
      }
    end
  end 
end

