$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'


describe "Neo4j & Lucene Transaction Synchronization:" do
  before(:all) do
    start
    undefine_class :TestNode
    class TestNode
      include Neo4j::NodeMixin
      property :name
      index :name
    end
  end
  after(:all) do
    stop
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
end