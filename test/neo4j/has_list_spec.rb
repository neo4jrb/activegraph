$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'spec_helper'


class XNode
  include Neo4j::NodeMixin
  property :name

  def to_s
    "node: #{name}"
  end
end


describe "ListNode (Neo4j::NodeMixin#has_list) with a size counter" do

  before(:all) do
    start

    class ListWithCounterNode
      include Neo4j::NodeMixin
      has_list :items, :counter => true
    end
  end

  before(:each) do
    start
    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish
    stop
  end

  it "should have a size method" do
    list = ListWithCounterNode.new
    list.items.should respond_to(:size)
  end

  it "should be zero when list is created" do
    list = ListWithCounterNode.new
    list.items.size.should == 0
  end

#  it "test it" do
#    node = Neo4j::Node.new
#
#    new_rel = []
#    if (@node.rel?(:foo))
#      # get that relationship
#      first = @node.rels.outgoing(@relationship_type).first
#
#      # delete this relationship
#      first.del
#      old_first = first.other_node(@node)
#      new_rel << (@node.rels.outgoing(@relationship_type) << other)
#      new_rel << (other.rels.outgoing(@relationship_type) << old_first)
#    else
#      # the first node will be set
#      new_rel << (@node.rels.outgoing(@relationship_type) << other)
#
#    node.lists{|list_item| list_item.prev.next = list_item.next if list_item.prev; list_item.size -= 1}
#
#  end
  
  it "should increase when you append items to the list" do
    list = ListWithCounterNode.new
    list.items.size.should == 0
    list.items << Neo4j::Node.new
    list.items.size.should == 1
    list.items << Neo4j::Node.new
    list.items.size.should == 2
  end

  it "should decrease when you remove items from the list" do
    list_node = ListWithCounterNode.new
    node1 = XNode.new
    node2 = XNode.new
    list_node.items << node1 << node2
    list_node.items.size.should == 2

    # when
    node1.del

    # then
    list_node.items.size.should == 1
  end
end

describe "ListNode (Neo4j::NodeMixin#has_list)" do
  before(:all) do
    start
    class ListNode
      include Neo4j::NodeMixin
      has_list :items
    end
  end

  before(:each) do
    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish
  end

  it "should impl. first method" do
    list = ListNode.new
    list.items.first.should be_nil
    node = XNode.new
    list.items << node
    list.items.first.should == node
  end


  it "should remove the node from the list when the node is deleted" do
    list_node = ListNode.new
    node1 = XNode.new
    node2 = XNode.new
    list_node.items << node1 << node2

    # when
    node2.del

    # then
    [*list_node.items].size.should == 1
  end

  it "should contain items after append one item to a list (#<<)" do
    list = ListNode.new
    list.list?(:items).should be_false
    list.items << XNode.new
    list.list?(:items).should be_true
  end

  it "should contain two items after appending two items (#<<)" do
    list_node = ListNode.new

    a = XNode.new
    a.name = 'a'
    list_node.items << a
    b = XNode.new
    b.name = 'b'
    list_node.items << b

    # check what is connected to what, list -> b -> a
    list_node.list(:items).next.should == b
    b.list(:items).next.should == a
    b.list(:items).prev.should == list_node
    b.list(:items).head.should == list_node
    list_node.list(:items).prev.should be_nil

  end

  it "should be empty when its empty (#empty?)" do
    list = ListNode.new
    list.items.empty?.should be_true
    list.items << XNode.new
    list.items.empty?.should be_false
  end

  it "should implement Enumerable" do
    list = ListNode.new
    list.items.empty?.should be_true
    a = XNode.new
    a.name = 'a'
    list.items << a
    b = XNode.new
    b.name = 'b'
    list.items << b
    list.items.should include(a)
    list.items.should include(b)
    list.items.should be_kind_of(Enumerable)
    [*list.items].size.should == 2
  end

end


describe "A node being member of two lists (Neo4j::NodeMixin#has_list)" do
  before(:all) do
    start
    class ListNode1
      include Neo4j::NodeMixin
      has_list :item_a, :counter => true
      has_list :item_b, :counter => true
    end

    class ListNode2
      include Neo4j::NodeMixin
      has_list :item_a, :counter => true
    end
  end

  before(:each) do
    Neo4j::Transaction.new
  end

  it "should have unique counters for each list" do
    list1 = ListNode1.new

    a = Neo4j::Node.new
    b = Neo4j::Node.new
    c = Neo4j::Node.new # c is member of both item_a and item_b lists

    list1.item_a << a
    list1.item_b << a << b << c

    # then
    list1.list("item_a").size.should == 1
    list1.list("item_b").size.should == 3
  end


  it "should remove the node from all lists it is member of when the node is deleted" do
    list1 = ListNode1.new
    list2 = ListNode1.new

    a = Neo4j::Node.new
    b = Neo4j::Node.new
    c = Neo4j::Node.new # c is member of both item_a and item_b lists

    list1.item_a << a << c
    list2.item_a << b << c
    list1.list('item_a').size.should == 2
    list2.list('item_a').size.should == 2

    # when
    c.del

    # then
    c.lists { fail } # not member of any lists
    list1.list('item_a').size.should == 1
    list2.list('item_a').size.should == 1
  end

  it "should know which lists a node is member of" do
    list1 = ListNode1.new
    list2 = ListNode1.new

    a = Neo4j::Node.new
    b = Neo4j::Node.new
    c = Neo4j::Node.new # c is member of both item_a and item_b lists

    list1.item_a << a << c
    list2.item_a << b << c

    # then
    lists = []
    a.lists {|list_item| lists << list_item.head}
    lists.should include(list1)
    lists.size.should == 1

    lists = []
    b.lists {|list_item| lists << list_item.head}
    lists.should include(list2)
    lists.size.should == 1

    lists = []
    c.lists {|list_item| lists << list_item.head}
    lists.should include(list1, list2)
    lists.size.should == 2
  end
end
