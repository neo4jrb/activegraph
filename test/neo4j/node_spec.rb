$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'spec_helper'


# ------------------------------------------------------------------------------
# Neo
#


describe Neo4j::Node do
  before(:all) do
    delete_db
  end

  after(:all) do
    stop
  end

  describe "#new" do
    it "returns an instance of org.neo4j.api.core.Node" do
      Neo4j::Transaction.run do
        # when
        node = Neo4j::Node.new
        # then
        node.should be_kind_of(org.neo4j.api.core.Node)
      end
    end

    it "raise an exception if not run in an Neo4j::Transaction" do
      lambda do
        Neo4j::Node.new
      end.should raise_error
    end
  end

  describe "#[key]" do
    before(:each) { Neo4j::Transaction.new; @node = Neo4j::Node.new}
    after(:each) { Neo4j::Transaction.finish}

    it "returns nil if the property is not defined" do
      @node[:unknown].should be_nil
    end

    it "returns nil if the property is not defined" do
      @node[:unknown].should be_nil
    end

    it "does a to_s on the key argument" do
      obj = Object.new

      def obj.to_s
        "abc"
      end

      @node[obj].should == @node["abc"]
    end

  end

  describe "#[key]=value" do
    before(:each) { Neo4j::Transaction.new; @node = Neo4j::Node.new}
    after(:each) { Neo4j::Transaction.finish}

    it "does a to_s on the key argument" do
      obj = Object.new

      def obj.to_s
        "abc"
      end

      @node[obj] = "hej"
      @node["abc"].should == "hej"
    end

    it "remove the property if value is nil" do
      # given
      @node[:foo] = "foo"
      @node.property?(:foo).should be_true

      # when
      @node[:foo] = nil

      # then
      @node.property?(:foo).should be_false
    end

    it "can set a String value that can be accessed by the #[key] operator" do
      @node[:unknown] = "hej"
      @node[:unknown].should == "hej"
    end

    it "can set a Integer value that can be accessed by the #[key] operator" do
      @node[:unknown] = 42
      @node[:unknown].should == 42
      @node[:unknown].should be_kind_of(Fixnum)
    end

    it "can set a Float value that can be accessed by the #[key] operator" do
      @node[:unknown] = 3.14
      @node[:unknown].should == 3.14
      @node[:unknown].should be_kind_of(Float)
    end

    it "can set a Double value that can be accessed by the #[key] operator" do
      @node[:unknown] = 3.123456789
      @node[:unknown].should == 3.123456789
      @node[:unknown].should be_kind_of(Float)
    end

    it "can set a boolean value that can be accessed by the #[key] operator" do
      @node[:true] = true
      @node[:false] = false

      @node[:true].should be_true
      @node[:false].should be_false
    end

  end

  describe "#rel?(symbol)" do
    before(:each) { Neo4j::Transaction.new; @node = Neo4j::Node.new}
    after(:each) { Neo4j::Transaction.finish}

    it "should return false if there are no outgoing relationship of given type" do
      @node.rel?(:something).should be_false
    end


    it "should return true if there is one or more outgoing relationships of given type" do
      node2 = Neo4j::Node.new
      @node.rels.outgoing(:foo) << node2
      @node.rel?(:foo).should be_true
    end
  end

  describe "#rels.outgoing(symbol) <<" do
    before(:each) { Neo4j::Transaction.new; @node = Neo4j::Node.new}
    after(:each) { Neo4j::Transaction.finish}

    it "should add an outgoing relationship of given type" do
      node2 = Neo4j::Node.new
      @node.rels.outgoing(:foo) << node2
      [*@node.rels.outgoing(:foo).nodes].should include(node2)
      [*@node.rels.outgoing(:foo).nodes].size.should == 1
    end

    it "should allow chain (<< node1 <<node2)" do
      node2 = Neo4j::Node.new
      node3 = Neo4j::Node.new
      @node.rels.outgoing(:foo) << node2 << node3
      [*@node.rels.outgoing(:foo).nodes].should include(node2, node3)
    end
  end

  describe "#rels.outgoing(symbol)" do
    before(:each) { Neo4j::Transaction.new; @node = Neo4j::Node.new}
    after(:each) { Neo4j::Transaction.finish}

    it ".each should not yield if there are no outgoing relationship of given type" do
      @node.rels.outgoing(:does_not_exit).each { fail "should not exist"}
    end

    it "should include (Enumerable#include) all org.neo4j.api.core.Relationship objects if there is no _classname property" do
      rel1 = @node.createRelationshipTo(Neo4j::Node.new, org.neo4j.api.core.DynamicRelationshipType.withName('foo'))
      rel2 = @node.createRelationshipTo(Neo4j::Node.new, org.neo4j.api.core.DynamicRelationshipType.withName('foo'))

      [*@node.rels.outgoing(:foo)].should include(rel1, rel2)
      [*@node.rels.outgoing(:foo)].size.should == 2
    end

    it ".each{} should yield Neo4j::RelationshipMixin objects if there is a _classname property" do
      pending
      @node.add_rel(:foo, Neo4j::SomeNode.new)
      @node.rels.outgoing(:foo).each {|r| r.should be_kind_of(Neo4j::RelationshipMixin)}
    end

    it ".first should return the first relationship" do
      @node.createRelationshipTo(Neo4j::Node.new, org.neo4j.api.core.DynamicRelationshipType.withName('foo'))
      @node.createRelationshipTo(Neo4j::Node.new, org.neo4j.api.core.DynamicRelationshipType.withName('foo'))

      # when
      actual = @node.rels.outgoing(:foo).first

      # then
      expected = @node.getRelationships().iterator.next()
      actual.should_not be_nil
      actual.should == expected
    end

    it "should return an Enumerable" do
      @node.rels.outgoing(:does_not_exit).should be_kind_of(Enumerable)
    end
  end

  describe "#props" do
    before(:each) { Neo4j::Transaction.new; @node = Neo4j::Node.new}
    after(:each) { Neo4j::Transaction.finish}

    it "should return an map containing only the key 'id' if there are no properties" do
      @node.props.keys.should include('id')
      @node.props.size.should == 1
    end

    it "should return a map of properties + the id of the node" do
      @node[:foo] = 123
      @node[:bar] = "hej"
      @node.props.keys.should include('id', 'foo', 'bar')
      @node.props.size.should == 3
      @node.props['foo'].should == 123
      @node.props['bar'].should == "hej"
    end

  end


  describe "#update" do
    before(:each) { Neo4j::Transaction.new; @node = Neo4j::Node.new}
    after(:each) { Neo4j::Transaction.finish}

    it "should add the given properties to the node" do
      @node.update :name => 'andreas', :score => 42
      # then
      @node[:name].should == 'andreas'
      @node[:score].should == 42
    end

    it "should keep old properties when adding new one" do
      @node[:old] = "value"
      @node.update :name => 'andreas', :score => 42
      # then
      @node[:name].should == 'andreas'
      @node[:score].should == 42
      @node[:old].should == "value"
    end

    it "should not keep old properties when adding new one when strict => true" do
      @node[:old] = "value"
      @node.update({:name => 'andreas', :score => 42}, :strict => true)
      # then
      @node[:name].should == 'andreas'
      @node[:score].should == 42
      @node[:old].should be_nil
    end

  end

  describe "#del" do
    before(:each) { Neo4j::Transaction.new; @node = Neo4j::Node.new}
    after(:each) { Neo4j::Transaction.finish}

    it "should delete the node" do
      id = @node.neo_id
      @node.del
      
      # then
      Neo4j::Transaction.finish
      Neo4j::Transaction.new

      Neo4j.load_node(id).should be_nil
    end

    it "should delete the node even if it has relationships to other nodes" do
      id = @node.neo_id
      @node.rels.outgoing(:foo) << Neo4j::Node.new

      # when
      @node.del

      # then
      Neo4j::Transaction.finish
      Neo4j::Transaction.new
      Neo4j.load_node(id).should be_nil
    end


    it "should delete all incoming and outgoing relationships" do
      rel_id_1 = @node.add_rel(:foo, Neo4j::Node.new).neo_id
      rel_id_2 = Neo4j::Node.new.add_rel(:bar, @node).neo_id

      # when
      @node.del

      # then
      Neo4j::Transaction.finish
      Neo4j::Transaction.new
      Neo4j.load_rel(rel_id_1).should be_nil
      Neo4j.load_rel(rel_id_2).should be_nil
    end

  end
end
