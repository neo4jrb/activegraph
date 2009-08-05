$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'



# ------------------------------------------------------------------------------
# Neo
# 

#$NEO_LOGGER.level = Logger::DEBUG

describe "Neo4j" do
  it "should not need to be started or stopped before using it" do
    undefine_class :Foo
    class Foo
      include Neo4j::NodeMixin
      property :name
      index :name
    end
    res = Foo.find(:name => 'kalle')
    res.size.should == 0
    Neo4j::Transaction.run do
      f = Foo.new
      f.name = 'kalle'
    end

    Neo4j::Transaction.run do
      res = Foo.find(:name => 'kalle')
      res.size.should == 1
      res[0].name.should == 'kalle'
    end
  end
end

describe Neo4j::Neo do
  before(:each) do
    start
  end

  after(:each) do
    stop
  end

  it "should return correct number of nodes when using Neo4j.number_of_nodes_in_use" do
    # only reference node exists
    Neo4j.number_of_nodes_in_use.should == 1

    # when created a node
    a = Neo4j::Transaction.run do
      Neo4j::Node.new
    end

    Neo4j.number_of_nodes_in_use.should == 2

    Neo4j::Transaction.run do
      a.delete
    end

    Neo4j.number_of_nodes_in_use.should == 1
  end
                                         
  it "should return correct number of properties when using Neo4j.number_of_properties_in_use" do
    # only reference node exists
    Neo4j.number_of_properties_in_use.should == 1

    # when created a node
    a = Neo4j::Transaction.run do
      Neo4j.ref_node[:foo] = 'bar'
    end

    Neo4j.number_of_properties_in_use.should == 2

    Neo4j::Transaction.run do
      Neo4j.ref_node[:foo] = nil
    end

    Neo4j.number_of_properties_in_use.should == 1
  end

  it "should only count properties using Neo4j.number_of_properties_in_use" do
    # only reference node exists
    node1 = node2 = nil
    Neo4j::Transaction.run do
      node1 = Neo4j::Node.new
      node2 = Neo4j::Node.new
    end
    
    Neo4j.number_of_properties_in_use.should == 1  # a bit weird, should be 3 since each node sets the classname property ...


    Neo4j::Transaction.run do
      node1.relationships.outgoing(:baaz) << node2
      Neo4j::Node.new
    end

    Neo4j.number_of_properties_in_use.should == 1
  end

  it "should return correct number of properties when using Neo4j.number_of_relationships_in_use" do
    # create two nodes that we can create relationships between
    node1 = node2 = nil
    Neo4j::Transaction.run do
      node1 = Neo4j::Node.new
      node2 = Neo4j::Node.new
    end

    Neo4j.number_of_relationships_in_use.should == 0

    # when created a relationship
    Neo4j::Transaction.run do
      node1.relationships.outgoing(:baaz) << node2
    end


    Neo4j.number_of_relationships_in_use.should == 1

    Neo4j::Transaction.run do
      node1.relationships.outgoing(:baaz)[node2].delete
    end

    Neo4j.number_of_relationships_in_use.should == 0
  end

  it "should return a new neo instance if neo has been stopped" do
    x = Neo4j.instance
    Neo4j.stop
    Neo4j.instance.should_not == x
  end

  it "should have a reference node" do
    ref_node = Neo4j.instance.ref_node
    ref_node.should_not be_nil
  end

  it "should find a node given its neo node id" do
    # given
    class TestNode
      include Neo4j::NodeMixin
    end
    Neo4j::Transaction.run do
      t1 = TestNode.new

      # when
      t2 = Neo4j.instance.find_node(t1.neo_node_id)

      # then
      t1.should == t2
    end

  end

  it "should not find a node that does not exist" do
    Neo4j::Transaction.run do
      n = Neo4j.instance.find_node(10)
      n.should be_nil
    end
  end


  it "should find a given relationship by id" do
    Neo4j::Transaction.run do
      n1 = Neo4j::Node.new
      n2 = Neo4j::Node.new
      rel = n1.relationships.outgoing(:foo) << n2

      r = Neo4j.load_relationship(rel.neo_relationship_id)

      rel.should == r
    end
  end


  it "should not find a given relationship by id that does not exist" do
    Neo4j::Transaction.run do
      n = Neo4j.load_relationship(101241)
      n.should be_nil
    end
  end

  it "should load a node even if it does not have a classname property" do
    Neo4j::Transaction.run do
      n = Neo4j::Node.new
      id = n.neo_node_id
      Neo4j.load(id).should_not be_nil

      # when classname property does not exist
      n[:classname] = nil

      # then it should be possible to load it again, default should be Neo4j::Node class
      node = Neo4j.load(id)
      node.should_not be_nil
      node.should be_kind_of(Neo4j::Node)
    end

  end


  it "should load a relationship even if it does not have a classname property" do
    Neo4j::Transaction.run do
      n1 = Neo4j::Node.new
      n2 = Neo4j::Node.new
      n1.relationships.outgoing(:foobaar) << n2
      r = n1.relationships.outgoing(:foobaar).first
      id = r.neo_relationship_id
      Neo4j.load_relationship(id).should_not be_nil

      # when classname property does not exist
      r[:classname] = nil

      # then it should be possible to load it again, default should be Neo4j::Node class
      rel = Neo4j.load_relationship(id)
      rel.should_not be_nil
      rel.should be_kind_of(Neo4j::Relationships::Relationship)
    end

  end

end
