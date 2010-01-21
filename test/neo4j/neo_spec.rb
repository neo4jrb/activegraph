$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'spec_helper'


# ------------------------------------------------------------------------------
# Neo
# 


describe Neo4j do
  before(:each) do
    delete_db
  end

  after(:each) do
    stop
  end

  describe "#start" do
    it "starts neo and sets #running? to true" do
      # when
      Neo4j.start
      # then
      Neo4j.running?.should be_true
    end
  end

  describe "#stop" do
    it "stops neo and sets #running? to false" do
      # when
      Neo4j.stop
      # then
      Neo4j.running?.should be_false
    end
  end

  describe "#running" do
    it "is false before it is started" do
      Neo4j.running?.should be_false
    end
  end

  describe "#instance" do
    it "returns an instance of org.neo4j.kernel.EmbeddedGraphDatabase" do
      Neo4j.instance.should be_kind_of(org.neo4j.kernel.EmbeddedGraphDatabase)
    end

    it "should start neo if it was not already started" do
      # given
      Neo4j.running?.should be_false
      # when
      Neo4j.instance
      # then
      Neo4j.running?.should be_true
    end
  end

  describe "#create_node" do
    it "should return a java object implementing interface org.neo4j.graphdb.Node" do
      Neo4j::Transaction.run do
        Neo4j.create_node.should be_kind_of(org.neo4j.graphdb.Node)
      end
    end

    it "should raise an exception if not run in a Neo4j::Transaction" do
      lambda do
        Neo4j.create_node
      end.should raise_error
    end
  end

  describe "#load_node" do
    before(:each) { Neo4j::Transaction.new}
    after(:each) { Neo4j::Transaction.finish}

    it "should load a neo4j node if it exist" do
      node = Neo4j::Node.new
      node2 = Neo4j.load_node(node.neo_id)
      node.should == node2
    end

    it "should return nil if it does not exist" do
      Neo4j.load_node(9999998).should be_nil
    end

    it "should return wrapped ruby node object if argument raw == false (default)" do
      class Foo
        include Neo4j::NodeMixin
      end
      foo = Foo.new
      foo2 = Neo4j.load_node(foo.neo_id)

      foo2.should be_kind_of(Foo)
      foo2.should == foo
    end

    it "should return the raw java object if argument raw == true" do
      class Foo
        include Neo4j::NodeMixin
      end
      foo = Foo.new
      foo2 = Neo4j.load_node(foo.neo_id, true)

      foo2.should_not be_kind_of(Foo)
      foo2.should == foo._java_node
    end

  end

  describe "#number_of_nodes_in_use" do

    it "should be 1 when neo data base is empty (only ref node exist)" do
      Neo4j.number_of_nodes_in_use.should == 1
    end
    
    it "should increase by one when a node is created" do
      # only reference node exists
      proc do
        # when created a node
        Neo4j::Transaction.run do
          Neo4j::Node.new
        end
      end.should change(Neo4j, :number_of_nodes_in_use).by(1)
    end

    it "should decrease by one when a node is deleted" do
      node = Neo4j::Transaction.run do
        Neo4j::Node.new
      end

      proc do
        # when created a node
        Neo4j::Transaction.run do
          node.delete
        end
      end.should change(Neo4j, :number_of_nodes_in_use).by(-1)
    end

  end


  describe "#number_of_properties_in_use" do
    it "should be 0 when neo data base is empty" do
      Neo4j.number_of_properties_in_use.should == 0
    end

    it "should increase the number when a new property is created" do
      proc do
        # when created a node
        Neo4j::Transaction.run do
          Neo4j.ref_node[:foo] = 'bar'
        end
      end.should change(Neo4j, :number_of_properties_in_use).by(1)
    end

    it "should decrease the number when a property is removed" do
      # when created a node
      Neo4j::Transaction.run do
        Neo4j.ref_node[:foo] = 'bar'
      end

      proc do
        # when created a node
        Neo4j::Transaction.run do
          Neo4j.ref_node[:foo] = nil
        end
      end.should change(Neo4j, :number_of_properties_in_use).by(-1)
    end

    it "should not change when a relationship or node is created" do
      proc do
        Neo4j.info
        # when created a node
        Neo4j::Transaction.run do
          Neo4j::Node.new.add_rel(:foo, Neo4j::Node.new) # add relationship and create nod
        end
        Neo4j.info        
      end.should_not change(Neo4j, :number_of_properties_in_use)
    end
  end


  describe "#number_of_relationships_in_use" do

    it "should be 0 when neo data base is empty" do
      Neo4j.number_of_relationships_in_use.should == 0
    end

    it "should increase by one when a relationship is created" do
      proc do
        # when created a node
        Neo4j::Transaction.run do
          Neo4j::Node.new.add_rel(:foo, Neo4j::Node.new)
        end
      end.should change(Neo4j, :number_of_relationships_in_use).by(1)
    end

    it "should decrease by one when a relationship is deleted" do
      rel = Neo4j::Transaction.run do
        Neo4j::Node.new.add_rel(:foo, Neo4j::Node.new)
      end

      proc do
        # when created a node
        Neo4j::Transaction.run do
          rel.delete
        end
      end.should change(Neo4j, :number_of_relationships_in_use).by(-1)
    end
  end

  describe "#all_nodes" do
    it "should return all nodes" do
      Neo4j::Transaction.new
      # given
      nodes = []
      Neo4j.all_nodes{|node| nodes << node}
      nodes.size.should == 1 # only reference node should be there
      nodes[0].should == Neo4j.ref_node

      # when
      n = Neo4j::Node.new

      # then
      nodes = []
      Neo4j.all_nodes {|node| nodes << node}
      nodes.size.should == 2
      nodes.should include(n)
    end
  end
end
