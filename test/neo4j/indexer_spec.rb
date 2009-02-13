$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'


include Neo4j

describe Indexer, " given property foo is indexed" do
  before(:each) do
    @lucene_index = []
    @indexer = Indexer.new(@lucene_index)
    @indexer.add_index_on_property(:foo)
  end

  it "should update index if property foo is changed" do
    # given
    node = mock('node')
    node.should_receive(:neo_node_id).and_return(123)
    node.should_receive(:foo).and_return('hi')

    # when
    @indexer.property_changed(node, :foo)

    # then
    @lucene_index.size.should == 1
    @lucene_index[0][:foo].should == 'hi'
    @lucene_index[0][:id].should == 123
  end

  it "should not update index if property bar is changed" do
    # given
    node = mock('node')

    # when
    @indexer.property_changed(node, :bar)

    # then
    @lucene_index.size.should == 0
  end

  it "should delete index if node is deleted" do
    # given
    node = mock('node')
    node.should_receive(:neo_node_id).and_return(42)
    @lucene_index.should_receive(:delete).with(42)

    # when
    @indexer.node_deleted(node)
  end

end

describe Indexer, " given property foo and bar is indexed" do
  before(:each) do
    @lucene_index = []
    @indexer = Indexer.new(@lucene_index)
    @indexer.add_index_on_property(:foo)
    @indexer.add_index_on_property(:bar)
  end

  it "should update index if property bar is changed" do
    # given
    node = mock('node')
    node.should_receive(:neo_node_id).and_return(123)
    node.should_receive(:bar).and_return('hi')
    node.should_receive(:foo).and_return('oj')

    # when
    @indexer.property_changed(node, :bar)

    # then
    @lucene_index.size.should == 1
    @lucene_index[0][:bar].should == 'hi'
    @lucene_index[0][:foo].should == 'oj'
    @lucene_index[0][:id].should == 123
  end

  it "should not update index if property baz is changed" do
    # given
    node = mock('node')

    # when
    @indexer.property_changed(node, :baz)

    # then
    @lucene_index.size.should == 0
  end

  it "should delete index if node is deleted" do
    # given
    node = mock('node')
    node.should_receive(:neo_node_id).and_return(42)
    @lucene_index.should_receive(:delete).with(42)

    # when
    @indexer.node_deleted(node)
  end

end

