require 'neo4j'
require 'spec_helper'


# specs for Neo4j::Neo


# ------------------------------------------------------------------------------
# the following specs are run inside one Neo4j transaction
# 

describe "When running in one transaction" do
  before(:all) do
    start
  end

  after(:all) do
    Neo4j::Transaction.run {
      remove_class_defs     # so that we can define the same class again        
    }
    stop
  end  
  
  before(:each) do
    @transaction = Neo4j::Transaction.new 
    @transaction.start
      puts "Before. ------- #{Neo4j::Transaction.current}"          
  end
  
  after(:each) do
    @transaction.failure # do not want to store anything
    @transaction.finish
  end
  
  
  # ------------------------------------------------------------------------------
  # Neo
  # 

  describe Neo4j::Neo do
  
    it "should not find a meta node of a class that does not exist" do
      puts "1. ------- #{Neo4j::Transaction.current}"
      n = Neo4j::Neo.instance.find_meta_node('Kalle2')
      n.should be_nil
    end
  
    it "should find the meta node of a class that exists" do
      puts "2. ------- #{Neo4j::Transaction.current}"      
      class Kalle2 < Neo4j::BaseNode 
      end
    
      n = Neo4j::Neo.instance.find_meta_node('Kalle2')
      n.should_not be_nil
      n.should be_kind_of(Neo4j::MetaNode)
    end
 
    it "should find an (ruby) object stored in neo given its unique id" do
      puts "3. ------- #{Neo4j::Transaction.current}"            
      class Foo45 < Neo4j::BaseNode
      end

      foo1 = Foo45.new
      foo2 = Neo4j::Neo.instance.find_node(foo1.neo_node_id)
      foo1.neo_node_id.should == foo2.neo_node_id
    end
    #node = Neo4j::find_node(id) ...
  
  end
end  
