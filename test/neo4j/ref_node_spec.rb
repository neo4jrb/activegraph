$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'




describe 'ReferenceNode' do
  before(:each) do
    stop
    undefine_class :MyNode
    class MyNode
      include Neo4j::NodeMixin
      property :name, :age
    end
  end
  
  it "has a reference to all created nodes" do
    Neo4j.ref_node.relations.should be_empty
    n = MyNode.new
    n.name = 'hoj'

    # then
    Neo4j.ref_node.relations.nodes.should include(n)
  end


  it "can add a reference to any node with a specific type" do
    n = MyNode.new
    n.name = 'hoj'
    Neo4j.ref_node.relations.outgoing('mytype').nodes.should_not include(n)

    # when
    Neo4j.ref_node.connect(n, 'mytype')
    
    # then
    Neo4j.ref_node.relations.outgoing('mytype').nodes.should include(n)
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

