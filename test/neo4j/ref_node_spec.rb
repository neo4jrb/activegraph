$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'




describe 'ReferenceNode' do
  before(:each) do
    undefine_class :MyNode, :MyNode2
    
    class MyNode
      include Neo4j::NodeMixin
      property :name, :age
    end

    class MyNode2
      include Neo4j::NodeMixin
    end

    start
  end

  after(:each) do
    stop
  end
 
  it "has a reference to a created node" do
    #should only have a reference to the reference node
    Neo4j.instance.index_node.relations.to_a.size.should == 1
    n = MyNode.new
    n.name = 'hoj'

    # then
    Neo4j.instance.index_node.relations.nodes.should include(n)
    Neo4j.instance.index_node.relations.to_a.size.should == 2
  end

  it "has a reference to all created nodes" do
    #should only have a reference to the reference node
    Neo4j.instance.index_node.relations.to_a.size.should == 1
    node1 = MyNode.new
    node2 = MyNode2.new
    node3 = MyNode2.new

    # then
    Neo4j.instance.index_node.relations.outgoing(:MyNode).nodes.should include(node1)
    Neo4j.instance.index_node.relations.outgoing(:MyNode2).nodes.should include(node2, node3)
    Neo4j.instance.index_node.relations.outgoing(:MyNode).nodes.to_a.size.should == 1
    Neo4j.instance.index_node.relations.outgoing(:MyNode2).nodes.to_a.size.should == 2

    MyNode.all.nodes.to_a.size.should == 1
    MyNode2.all.nodes.to_a.size.should == 2
  end

  it "can allow to create my own relationships (with has_n,has_one) from the reference node" do
    node = MyNode.new
    node.name = "ojoj"
  
    # when
    Neo4j.ref_node.class.has_one :my_node
  
    # then
    Neo4j.ref_node.my_node = node
    Neo4j.ref_node.my_node.should == node
    Neo4j.ref_node.my_node.name.should == "ojoj"
  end

end

