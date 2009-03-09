$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'


include Neo4j

describe Indexer, " given property foo is indexed" do
  before(:each) do
    @node_class = mock('nodeClass')
    @node_class.should_receive(:root_class).any_number_of_times.and_return("Foo")
    Indexer.clear_all_instances
    @indexer = Indexer.instance @node_class
    @indexer.add_index_on_property(:foo)
  end

  it "should update index if property foo is changed" do
    # given and then
    node = mock('node')
    node.should_receive(:class).any_number_of_times.and_return(@node_class)
    node.should_receive(:neo_node_id).and_return(42)
    node.should_receive(:foo).and_return("Hi")
    
    index = []
    @indexer.stub!(:lucene_index).and_return index

    # when
    @indexer.on_property_changed(node, :foo)

    # then
    index.size.should == 1
    index[0][:id].should == 42
    index[0][:foo].should == "Hi"
    puts "INDEX="+index.inspect
  end

#  it "should set foo and id fields in the lucene index when index is updated" do
#    # given
#    node = mock('node')
#    node.should_receive(:neo_node_id).and_return(123)
#    node.should_receive(:foo).and_return('hi')
#
#    # when
#    lucene_index = []
#    @indexer.update_index(lucene_index, node)
#
#    # then
#    lucene_index.size.should == 1
#    lucene_index[0][:foo].should == 'hi'
#    lucene_index[0][:id].should == 123
#  end
#
#
#  it "should not update index if property bar is changed" do
#    # given and then
#    node = mock('node')
#
#    # when
#    @indexer.on_property_changed(node, :bar)
#  end


end
#
#describe Indexer, " given property foo and bar is indexed" do
#  before(:each) do
#    @indexer = Indexer.new
#    @indexer.add_index_on_property(:foo)
#    @indexer.add_index_on_property(:bar)
#  end
#
#  it "should update index if property foo is changed" do
#    # given and then
#    node = mock('node')
#    node.should_receive(:update_index)
#
#    # when
#    @indexer.on_property_changed(node, :foo)
#  end
#
#  it "should update index if property bar is changed" do
#    # given and then
#    node = mock('node')
#    node.should_receive(:update_index)
#
#    # when
#    @indexer.on_property_changed(node, :foo)
#  end
#
#  it "should update index if both properties bar and foo are changed" do
#    # given and then
#    node = mock('node')
#    node.should_receive(:update_index).twice
#
#    # when
#    @indexer.on_property_changed(node, :foo)
#    @indexer.on_property_changed(node, :bar)
#  end
#
#  it "should not update index if property baaz is changed" do
#    # given and then
#    node = mock('node')
#
#    # when
#    @indexer.on_property_changed(node, :baaz)
#  end
#
#  it "should set foo, bar and id fields in the lucene index when index is updated" do
#    # given
#    node = mock('node')
#    node.should_receive(:neo_node_id).and_return(123)
#    node.should_receive(:bar).and_return('hi')
#    node.should_receive(:foo).and_return('oj')
#
#    # when
#    lucene_index = []
#    @indexer.update_index(lucene_index, node)
#
#    # then
#    lucene_index.size.should == 1
#    lucene_index[0][:bar].should == 'hi'
#    lucene_index[0][:foo].should == 'oj'
#    lucene_index[0][:id].should == 123
#  end
#
#
#end
#
#describe Indexer, " given property foo is indexed in relation 'friends'" do
#  before(:all) do
#    class AbcNode
#      include Neo4j::NodeMixin
#      has_n :friends
#      property :foo
#    end
#
#    @me = AbcNode.new
#    @friend1 = AbcNode.new
#    @friend1.foo = 'friend1'
#    @friend2 = AbcNode.new
#    @friend2.foo = 'friend2'
#    @me.friends << @friend1 << @friend2
#  end
#
#  after(:all) do
#    stop
#  end
#
#
#  before(:each) do
#    @indexer = Indexer.new()
#    @indexer.add_index_in_relation_on_property('friends', :friends, :foo)
#  end
#
#  it "should update index on its 'friends' related nodes when foo is changed (mocked)" do
#    me = mock('me')
#    friend1 = mock('friend1')
#    friend1.should_receive(:update_index)
#    relation = mock('relation')
#    nodes = mock('nodes')
#    #mock: node.relations.both(@rel_type).nodes
#    me.should_receive(:relations).and_return(relation)
#    relation.should_receive(:both).with(:friends).and_return(nodes)
#    nodes.should_receive(:nodes).and_return([friend1])
#
#    @indexer.on_property_changed(me, :foo)
#  end
#
#  it "should update index on its 'friends' related nodes when foo is changed" do
#    @indexer.on_property_changed(@me, :foo)
#  end
#
#  it "should not update index on its 'friends' related nodes when bar is changed" do
#    @indexer.on_property_changed(mock('me'), :bar)
#  end
#
#  it "should set friends.foo and id fields in the lucene index when index is updated" do
#    lucene_index = []
#    @indexer.update_index(lucene_index, @me)
#    lucene_index.size.should == 1
#    index1 = lucene_index[0]
#    index1[:id].should == 1
#    index1[:"friends.foo"].size.should == 2
#    index1[:"friends.foo"].should include("friend1")
#    index1[:"friends.foo"].should include("friend2")
#  end
#end
#
#describe Indexer, " given properties foo and bar is indexed in relation 'friends'" do
#  before(:all) do
#    class AbcdNode
#      include Neo4j::NodeMixin
#      has_n :friends
#      property :foo
#      property :bar
#    end
#
#    @me = AbcdNode.new
#    @friend1 = AbcdNode.new
#    @friend1.foo = 'friend1'
#    @friend1.bar = 'hi1'
#    @friend2 = AbcdNode.new
#    @friend2.foo = 'friend2'
#    @friend2.bar = 'hi2'
#    @me.friends << @friend1 << @friend2
#  end
#
#  after(:all) do
#    stop
#  end
#
#  before(:each) do
#    @indexer = Indexer.new()
#    @indexer.add_index_in_relation_on_property('friends', :friends, :foo)
#    @indexer.add_index_in_relation_on_property('friends', :friends, :bar)
#
#  end
#
#  it "should set friends.foo and friends.bar and id fields in the lucene index when index is updated" do
#    lucene_index = []
#    @indexer.update_index(lucene_index, @me)
#    lucene_index.size.should == 1
#    index1 = lucene_index[0]
#    index1[:id].should == 1
#    index1[:"friends.foo"].size.should == 2
#    index1[:"friends.foo"].should include("friend1")
#    index1[:"friends.foo"].should include("friend2")
#
#    index1[:"friends.bar"].size.should == 2
#    index1[:"friends.bar"].should include("hi1")
#    index1[:"friends.bar"].should include("hi2")
#  end
#
#end