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

end

