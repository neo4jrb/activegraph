$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'spec_helper'


class BaseNode
  include Neo4j::NodeMixin
end



#describe "placebo transaction" do
##  before(:all) do start end
#  after(:all)  do stop  end
#
#  it "should not change properties" do
#    neo = org.neo4j.kernel.EmbeddedGraphDatabase.new '/var/tmp/neo4jtest'
#    tx1 = neo.begin_tx
#    tx2 = neo.begin_tx
#    puts "TX1 " + tx1.java_object.java_type
#    puts "TX2 " + tx2.java_object.java_type
#    tx1.java_object.java_type.should == 'org.neo4j.kernel.EmbeddedGraphDatabase$TransactionImpl'
#    tx2.java_object.java_type.should == 'org.neo4j.kernel.EmbeddedGraphDatabase$PlaceboTransaction'
#    tx2.finish
#    tx1.finish
#    neo.shutdown
#  end
#
#end

describe "transaction rollback" do
  before(:all) do
    start
  end
  after(:all)  do
    stop
  end

  it "should not change properties" do
    node = Neo4j::Transaction.run { b = BaseNode.new; b[:foo] = 'foo'; b }

    # when doing a rollback
    Neo4j::Transaction.run { |t|
      node[:foo] = "changed"
      node[:foo].should  == "changed"
      t.failure
    }

    # then
    Neo4j::Transaction.run { node[:foo].should == 'foo'   }
  end

  it "should rollback a transaction when an exception is thrown"  do
    node = Neo4j::Transaction.run { b = BaseNode.new; b[:foo] = 'foo'; b }

    # when doing a rollback
    lambda do
      Neo4j::Transaction.run { |t|
        node[:foo] = "changed"
        node[:foo].should  == "changed"
        raise "BOOOM"
      }
    end.should raise_error
    
    # then
    Neo4j::Transaction.run { node[:foo].should == 'foo'   }

  end

end



describe "When neo has been restarted" do

  describe Neo4j do
    before(:all) do
      start
    end

    after(:all) do
      stop
    end


    it "should load node using its id" do
      node = nil
      Neo4j::Transaction.run {
        node = BaseNode.new
        node[:baaz] =  "hello"
      }

      Neo4j.stop
      Neo4j.start

      Neo4j::Transaction.run {
        node2 = Neo4j.load_node(node.neo_id)
        node2[:baaz].should == "hello"
      }
    end
  end
end

