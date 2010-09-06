$LOAD_PATH.unshift File.join(File.dirname(__FILE__))
require 'spec_helper'


describe Neo4j::NodeMixin do

  class MyNode
    include Neo4j::NodeMixin

    property :name
  end

#  subject do
#    MyNode.new
#  end

  before(:all) do
      FileUtils.rm_rf Neo4j.config[:storage_path]
      FileUtils.mkdir_p(Neo4j.config[:storage_path])
  end

  after(:all) { Neo4j.shutdown }

  before(:each) do
    Neo4j::Transaction.new
  end

  after(:each) do
    # make sure we clean up after each test
    Neo4j::Node.rm_index(:name)
    Neo4j::Transaction.finish
  end


  it "#[] and #[]= read and sets a neo4j property" do
    n = MyNode.new
    n.name = 'kalle'
    n.name.should == 'kalle'
  end


  it "Neo4j::Node.load loads the correct class" do
    n1 = MyNode.new
    n2 = Neo4j::Node.load(n1.id)
    # then
    n1.should == n2
  end
end