$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'spec_helper'

describe Neo4j::BatchInserter do

  it "should accept Neo4j::Node.new and Neo4j::Relationship.new" do
    Neo4j.stop # must not have a running neo4j while using batch inserter

    class Foo
      include Neo4j::NodeMixin
    end
    a = b = nil
    Neo4j::BatchInserter.new do |b|
      a = Neo4j::Node.new :name => 'a'
      b = Neo4j::Node.new :name => 'b'
      Neo4j::Relationship.new(:friend, a, b, :since => '2001-01-01')
    end

    Neo4j::Transaction.new
    node_a = Neo4j.load_node(a.neo_id)
    node_a[:name].should == 'a'
    Neo4j::Transaction.finish
  end

  it "should accept Neo4j::NodeMixin classes" do
    pending "Not working yet - properties are not set using batch inserter"
    Neo4j.stop # must not have a running neo4j while using batch inserter

    class Foo
      include Neo4j::NodeMixin
    end


    c = nil
    Neo4j::BatchInserter.new do |b|
      c = Foo.new :key1 => 'val1', :key2 => 'val2'
      c[:key] = 'val1'
    end

    Neo4j::Transaction.new
    node_c = Neo4j.load_node(c.neo_id)
    node_c[:key1].should == 'val1'
    node_c.should be_kind_of(Foo)
    Neo4j::Transaction.finish
  end
end
