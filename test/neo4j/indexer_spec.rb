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
    # given and then
    node = mock('node')
    node.should_receive(:update_index)

    # when
    @indexer.on_property_changed(node, :foo)
  end

  it "should set foo and id fields in the lucene index when index is updated" do
    # given
    node = mock('node')
    node.should_receive(:neo_node_id).and_return(123)
    node.should_receive(:foo).and_return('hi')

    # when
    @indexer.update_index(node)

    # then
    @lucene_index.size.should == 1
    @lucene_index[0][:foo].should == 'hi'
    @lucene_index[0][:id].should == 123
  end


  it "should not update index if property bar is changed" do
    # given and then
    node = mock('node')

    # when
    @indexer.on_property_changed(node, :bar)
  end

  it "should delete index if node is deleted" do
    # given and then
    node = mock('node')
    node.should_receive(:neo_node_id).and_return(42)
    @lucene_index.should_receive(:delete).with(42)

    # when
    @indexer.on_node_deleted(node)
  end

end

describe Indexer, " given property foo and bar is indexed" do
  before(:each) do
    @lucene_index = []
    @indexer = Indexer.new(@lucene_index)
    @indexer.add_index_on_property(:foo)
    @indexer.add_index_on_property(:bar)
  end

  it "should update index if property foo is changed" do
    # given and then
    node = mock('node')
    node.should_receive(:update_index)

    # when
    @indexer.on_property_changed(node, :foo)
  end

  it "should update index if property bar is changed" do
    # given and then
    node = mock('node')
    node.should_receive(:update_index)

    # when
    @indexer.on_property_changed(node, :foo)
  end

  it "should update index if both properties bar and foo are changed" do
    # given and then
    node = mock('node')
    node.should_receive(:update_index).twice

    # when
    @indexer.on_property_changed(node, :foo)
    @indexer.on_property_changed(node, :bar)
  end

  it "should not update index if property baaz is changed" do
    # given and then
    node = mock('node')

    # when
    @indexer.on_property_changed(node, :baaz)
  end

  it "should set foo, bar and id fields in the lucene index when index is updated" do
    # given
    node = mock('node')
    node.should_receive(:neo_node_id).and_return(123)
    node.should_receive(:bar).and_return('hi')
    node.should_receive(:foo).and_return('oj')

    # when
    @indexer.update_index(node)

    # then
    @lucene_index.size.should == 1
    @lucene_index[0][:bar].should == 'hi'
    @lucene_index[0][:foo].should == 'oj'
    @lucene_index[0][:id].should == 123
  end


  it "should delete index if node is deleted" do
    # given
    node = mock('node')
    node.should_receive(:neo_node_id).and_return(42)
    @lucene_index.should_receive(:delete).with(42)

    # when
    @indexer.on_node_deleted(node)
  end

end

describe Indexer, " given property foo is indexed in relation 'friends'" do
  before(:each) do
    @lucene_index = []
    @indexer = Indexer.new(@lucene_index)
    @indexer.add_index_in_relation_on_property('friends.foo', :friends, :foo)
  end

  it "should update index on its 'friends' related nodes when foo is changed" do
    # TODO have to make this easier to test and mock
    me = mock('me')
    friend1 = mock('friend1')
    friend1.should_receive(:update_index)
    relation = mock('relation')
    nodes = mock('nodes')
    #mock: node.relations.both(@rel_type).nodes
    me.should_receive(:relations).and_return(relation)
    relation.should_receive(:both).with(:friends).and_return(nodes)
    nodes.should_receive(:nodes).and_return([friend1])
    
    @indexer.on_property_changed(me, :foo)
  end

  it "should not update index on its 'friends' related nodes when bar is changed" do
    @indexer.on_property_changed(mock('me'), :bar)
  end
end