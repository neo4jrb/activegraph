$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'spec_helper'

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

    rel = a.add_rel(:foo, b)
    rel[:_cascade_delete_outgoing] = true

    c.rels.outgoing(:foo) << d

    # when
    b.del
    a.del

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new
    Neo4j.load_node(a.neo_id).should be_nil
    Neo4j.load_node(b.neo_id).should be_nil
    Neo4j.load_node(c.neo_id).should_not be_nil
    Neo4j.load_node(d.neo_id).should_not be_nil
  end


  it "should delete all outgoing nodes if relationship has property _cascade_delete_outgoing " do
    a = Neo4j::Node.new
    b = Neo4j::Node.new
    c = Neo4j::Node.new
    d = Neo4j::Node.new

    rel = a.add_rel(:foo, b)
    rel[:_cascade_delete_outgoing] = true

    rel2 = b.add_rel(:foo, c)
    rel2[:_cascade_delete_outgoing] = true

    b.rels.outgoing(:foo) << d

    # when
    a.del

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load_node(b.neo_id).should be_nil
    Neo4j.load_node(c.neo_id).should be_nil
    Neo4j.load_node(d.neo_id).should_not be_nil
  end

  it "should delete node if it does not have relationships with property _cascade_delete_incoming" do
    a = Neo4j::Node.new {|n| n[:name] = 'a'}
    b = Neo4j::Node.new {|n| n[:name] = 'b'}
    c = Neo4j::Node.new {|n| n[:name] = 'c'}
    d = Neo4j::Node.new {|n| n[:name] = 'd'}

    a.add_rel(:foo, b)[:_cascade_delete_incoming] = a.neo_id
    a.add_rel(:foo, c)[:_cascade_delete_incoming] = a.neo_id

    b.rels.outgoing(:foo) << d

    # only when a's all incoming nodes are deleted
    Neo4j.load_node(a.neo_id).should_not be_nil
    b.del
    c.del
    d.del

    # then a will be deleted since it does not have any outgoing relationships with property _cascade_delete_incoming
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load_node(a.neo_id).should be_nil
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
    f.del

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load_node(f1.neo_id).should be_nil
    Neo4j.load_node(f2.neo_id).should be_nil
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
    fa.del

    # then
    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load_node(fa.neo_id).should be_nil
    Neo4j.load_node(fa1.neo_id).should_not be_nil
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
    fa.del

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load_node(fa1.neo_id).should be_nil
    Neo4j.load_node(fb1.neo_id).should_not be_nil
    Neo4j.load_node(fc1.neo_id).should_not be_nil
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
    f1.del

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load_node(f2.neo_id).should_not be_nil
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
    f1.del
    f2.del

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load_node(f.neo_id).should be_nil
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
    f.del

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load_node(f1.neo_id).should be_nil
    Neo4j.load_node(f2.neo_id).should be_nil
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
    f1.del
    f2.del

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load_node(f.neo_id).should be_nil
    Neo4j.load_node(f1.neo_id).should be_nil
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
    f.del

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load_node(f1.neo_id).should be_nil
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
    f1.del

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    Neo4j.load_node(f.neo_id).should be_nil
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
    class OrderLineX
      include Neo4j::NodeMixin
    end

    class OrderStatusX
      include Neo4j::NodeMixin
      has_one :order, :cascade_delete => :incoming # delete the order status when the order is deleted
    end

    class OrderX
      include Neo4j::NodeMixin
      has_n :order_lines, :cascade_delete => :incoming # delete order when all its order_lines are deleted
    end

    # delete order when line1 and line2 is deleted
    # delete order when all its relationships are deleted except cascade_delete incoming

    line1 = OrderLineX.new
    line2 = OrderLineX.new

    order = OrderX.new
    order.order_lines << line1
    order.order_lines << line2

    status = OrderStatusX.new
    status.order = order

    # delete order when it has no more
    # when
    line1.del
    line2.del

    # then
    Neo4j::Transaction.finish
    Neo4j::Transaction.new
    
    Neo4j.load_node(status.neo_id).should be_nil
  end
end