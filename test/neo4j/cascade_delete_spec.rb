$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'


describe "Cascade Delete" do

  before(:all) do
    start
    Neo4j::Transaction.new
  end

  after(:all) do
    stop
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
