require 'neo4j'
require 'spec_helper'

# ------------------------------------------------------------------------------
# the following specs are run when doing  a rollback in one transaction 
# 

describe "Transaction" do
  before(:all) do start end
  after(:all)  do stop  end  
  
  it "should return the value of the transaction performed" do
    val = Neo4j::transaction{ 42} 
    val.should == 42
  end
end

describe "When doing a rollback in one transaction" do
  before(:all) do start end
  after(:all)  do stop  end  


  it "should not change properties" do
    # given
    node = Neo4j::BaseNode.new {|n| n.foo = 'foo'}

    # when doing a rollback
    Neo4j::transaction { |t|
      node.foo = "changed"
      t.failure
    }
    
    # then
    Neo4j::transaction { node.foo.should == 'foo'   }
  end
    
  it "should support chained transactions" do
    # given
    pending # chaining transaction does not work, should it ?
    node = Neo4j::BaseNode.new {|n| n.foo = 'foo'}
    
    Neo4j::transaction do 
      node.bar = "bar" 
      # when doing a rollback on a sub transaction
      Neo4j::transaction { |t| node.bar = "changed"; node.foo = "changed"; t.failure }
    end
    
    
    # then only that transaction should be rolled back
    Neo4j::transaction {  
      node.foo.should == 'foo' 
      node.bar.should == 'bar'
    }
  end
  
  it "should not create a meta class" do
    # given
    Neo4j::transaction { |t|
      class FooBar1 < Neo4j::BaseNode
      end

      # when doing rollback
      t.failure
    }
    
    # then
    Neo4j::transaction {
      metanode = Neo4j::Neo.instance.find_meta_node('FooBar1')
      metanode.should be_nil
    }
  end
  
end


# ------------------------------------------------------------------------------
# the following specs are not always run inside ONE Neo4j transaction
# 

describe "When neo has been restarted" do

  def restart
    Neo4j::Neo.instance.stop
    Neo4j::Neo.instance.start DB_LOCATION
  end
  
  describe Neo4j::Neo do
    before(:all) do
      start
    end

    after(:all) do
      stop
    end  
    
    it "should contain referenses to all meta nodes" do
      # given
      Neo4j::transaction {
        metas = Neo4j::Neo.instance.meta_nodes.nodes
        metas.to_a.size.should == 0
      }
      
      class Foo < Neo4j::BaseNode
      end
      
      
      Neo4j::transaction {
        metas = Neo4j::Neo.instance.meta_nodes.nodes
        metas.to_a.size.should == 1
        meta = Neo4j::Neo.instance.find_meta_node('Foo')
        meta.should_not be_nil
        meta.ref_classname.should == "Foo"
      }
      
      # when 
      restart
      
      # then
      Neo4j::transaction {
        metas = Neo4j::Neo.instance.meta_nodes.nodes
        metas.to_a.size.should == 1
        meta = Neo4j::Neo.instance.find_meta_node('Foo')
        meta.should_not be_nil
        meta.ref_classname.should == "Foo"
      }
      
      
    end
    
    it "should have unique node ids for the Meta Node" do
      # when Neo4j is restarted make sure that the node representing the class
      # has the same node_id
    
      class Foo < Neo4j::BaseNode
      end

      id1 = Neo4j::transaction { Neo4j::Neo.instance.find_meta_node('Foo').neo_node_id  }

      restart
      
      id2 = Neo4j::transaction { Neo4j::Neo.instance.find_meta_node('Foo').neo_node_id }
      id1.should == id2
    end
    
    it "should load node using its id" do
      node = Neo4j::BaseNode.new {|n|
        n.baaz = "hello"
      }
      
      restart
      
      Neo4j::transaction {
        node2 = Neo4j::Neo.instance.find_node(node.neo_node_id)
        node2.baaz.should == "hello"
      }
    end
  end 
end

