$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'

describe "Cascade Delete for raw relationships" do

  before(:all) do
    start
    Neo4j::Transaction.new
  end

  after(:all) do
    stop
  end

  it "should only cascade delete on relationships declared as cascade delete" do
    a = Neo4j::Node.new {|n| n[:name] = 'a'}
    b = Neo4j::Node.new {|n| n[:name] = 'b'}
    c = Neo4j::Node.new {|n| n[:name] = 'c'}
    d = Neo4j::Node.new {|n| n[:name] = 'd'}

    rel = a.relationships.outgoing(:foo) << b
    rel[:_cascade_delete_outgoing] = true

    rel2 = c.relationships.outgoing(:foo) << d

    # when
    b.delete
    a.delete

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new
    Neo4j.load(a.neo_node_id).should be_nil
    Neo4j.load(b.neo_node_id).should be_nil
    Neo4j.load(c.neo_node_id).should_not be_nil
    Neo4j.load(d.neo_node_id).should_not be_nil
  end


  it "should delete all outgoing nodes if relationship has property _cascade_delete_outgoing " do
    a = Neo4j::Node.new {|n| n[:name] = 'a'}
    b = Neo4j::Node.new {|n| n[:name] = 'b'}
    c = Neo4j::Node.new {|n| n[:name] = 'c'}
    d = Neo4j::Node.new {|n| n[:name] = 'd'}

    rel = a.relationships.outgoing(:foo) << b
    rel[:_cascade_delete_outgoing] = true

    rel2 = b.relationships.outgoing(:foo) << c
    rel2[:_cascade_delete_outgoing] = true

    b.relationships.outgoing(:foo) << d

    # when
    a.delete

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load(b.neo_node_id).should be_nil
    Neo4j.load(c.neo_node_id).should be_nil
    Neo4j.load(d.neo_node_id).should_not be_nil
  end

  it "should delete node if it does not have relationships with property _cascade_delete_incoming" do
    a = Neo4j::Node.new {|n| n[:name] = 'a'}
    b = Neo4j::Node.new {|n| n[:name] = 'b'}
    c = Neo4j::Node.new {|n| n[:name] = 'c'}
    d = Neo4j::Node.new {|n| n[:name] = 'd'}

    (a.relationships.outgoing(:foo) << b)[:_cascade_delete_incoming] = a.neo_node_id
    (a.relationships.outgoing(:foo) << c)[:_cascade_delete_incoming] = a.neo_node_id

    b.relationships.outgoing(:foo) << d

    # only when a's all incoming nodes are deleted
    Neo4j.load(a.neo_node_id).should_not be_nil
    b.delete
    c.delete
    d.delete

    # then a will be deleted since it does not have any outgoing relationships with property _cascade_delete_incoming
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load(a.neo_node_id).should be_nil
  end
end

describe "Cascade Delete For #hasList" do

  before(:all) do
    start
    Neo4j::Transaction.new
  end

  after(:all) do
    stop
  end

  it "should delete all list members for outgoing cascade delete" do
    class Foo
      include Neo4j::NodeMixin
      has_list :stuff, :cascade_delete => :outgoing
    end

    f = Foo.new
    f1 = Neo4j::Node.new
    f2 = Neo4j::Node.new
    f.stuff << f1
    f.stuff << f2

    # when
    f.delete

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load(f1.neo_node_id).should be_nil
    Neo4j.load(f2.neo_node_id).should be_nil
  end


  it "should not delete list members if it is not cascade delete" do
    class Foo
      include Neo4j::NodeMixin
      has_list :abc
    end

    fa = Foo.new
    fa1 = Neo4j::Node.new
    fa.abc << fa1

    # when
    fa.delete

    # then
    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load(fa.neo_node_id).should be_nil
    Neo4j.load(fa1.neo_node_id).should_not be_nil
  end

  it "should not delete other list items for outgoing cascade delete" do
    class Foo
      include Neo4j::NodeMixin
      has_list :stuff, :cascade_delete => :outgoing
      has_list :things, :cascade_delete => :outgoing
    end

    class FooBar
      include Neo4j::NodeMixin
      has_list :stuff, :cascade_delete => :outgoing
    end

    fa = Foo.new
    fa1 = Neo4j::Node.new
    fa.stuff << fa1


    fb = Foo.new
    fb1 = Neo4j::Node.new
    fb.things << fb1

    fc = Foo.new
    fc1 = Neo4j::Node.new
    fc.things << fc1

    # when
    fa.delete

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load(fa1.neo_node_id).should be_nil
    Neo4j.load(fb1.neo_node_id).should_not be_nil
    Neo4j.load(fc1.neo_node_id).should_not be_nil
  end

  it "should not delete all list members for outgoing cascade delete when one list item is deleted" do
    class Foo
      include Neo4j::NodeMixin
      has_list :stuff, :cascade_delete => :outgoing
    end

    f = Foo.new
    f1 = Neo4j::Node.new
    f2 = Neo4j::Node.new
    f.stuff << f1
    f.stuff << f2

    # when
    f1.delete

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load(f2.neo_node_id).should_not be_nil
  end

  it "should delete the list node for incoming cascade delete when all its list items has been deleted" do
    class Foo
      include Neo4j::NodeMixin
      has_list :stuff, :cascade_delete => :incoming
    end

    f = Foo.new
    f1 = Neo4j::Node.new
    f2 = Neo4j::Node.new
    f.stuff << f1
    f.stuff << f2


    # when
    f1.delete
    f2.delete

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load(f.neo_node_id).should be_nil
  end

end


describe "Cascade Delete For #hasN" do

  before(:all) do
    start
    Neo4j::Transaction.new
  end

  after(:all) do
    stop
  end

  it "should delete all related nodes when root node is deleted for outgoing cascade delete" do
    class Things
      include Neo4j::NodeMixin
      has_n :stuff, :cascade_delete => :outgoing
    end

    f = Things.new
    f1 = Neo4j::Node.new
    f2 = Neo4j::Node.new
    f.stuff << f1
    f.stuff << f2


    # when
    f.delete

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load(f1.neo_node_id).should be_nil
    Neo4j.load(f2.neo_node_id).should be_nil
  end


  it "should delete all related nodes when root node is deleted for incoming cascade delete" do
    class Things
      include Neo4j::NodeMixin
      has_n :stuff, :cascade_delete => :incoming
    end

    f = Things.new
    f1 = Neo4j::Node.new
    f2 = Neo4j::Node.new
    f.stuff << f1
    f.stuff << f2


    # when
    f1.delete
    f2.delete

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load(f.neo_node_id).should be_nil
    Neo4j.load(f1.neo_node_id).should be_nil
  end


end


describe "Cascade Delete For #hasOne" do

  before(:all) do
    start
    Neo4j::Transaction.new
  end

  after(:all) do
    stop
  end

  it "should delete all related nodes when root node is deleted for outgoing cascade delete" do
    class Things
      include Neo4j::NodeMixin
      has_one :thing, :cascade_delete => :outgoing
    end

    f = Things.new
    f1 = Neo4j::Node.new
    f.thing = f1


    # when
    f.delete

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load(f1.neo_node_id).should be_nil
  end


  it "should delete all related nodes when root node is deleted for incoming cascade delete" do
    class Things
      include Neo4j::NodeMixin
      has_one :thing, :cascade_delete => :incoming
    end

    f = Things.new
    f1 = Neo4j::Node.new
    f.thing = f1

    # when
    f1.delete

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load(f.neo_node_id).should be_nil
  end

end

describe "Cascade Delete chained" do
  before(:all) do
    start
    Neo4j::Transaction.new
  end

  after(:all) do
    stop
    undefine_class :OrderLine, :OrderStatus, :Order
  end
  
  it "should delete a chained relationship of cascaded objects" do
    # OrderStatus ---> Order ---*>OrderLine
    class OrderLine
      include Neo4j::NodeMixin
    end

    class OrderStatus
      include Neo4j::NodeMixin
      has_one :order, :cascade_delete => :incoming # delete the order status when the order is deleted
    end

    class Order
      include Neo4j::NodeMixin
      has_n :order_lines, :cascade_delete => :incoming # delete order when all its order_lines are deleted
    end

    # delete order when line1 and line2 is deleted
    # delete order when all its relationships are deleted except cascade_delete incoming

    line1 = OrderLine.new
    line2 = OrderLine.new

    order = Order.new
    order.order_lines << line1
    order.order_lines << line2

    status = OrderStatus.new
    status.order = order

    # delete order when it has no more
    # when
    line1.delete
    line2.delete

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new
    
    Neo4j.load(status.neo_node_id).should be_nil
  end
end