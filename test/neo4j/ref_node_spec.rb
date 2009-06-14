$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'
require 'extensions/reindexer'



class RefTestNode
  include Neo4j::NodeMixin
  property :name, :age
end

class RefTestNode2
  include Neo4j::NodeMixin
end


describe 'ReferenceNode' do
  before(:all) do
    start
  end

  after(:all) do
    stop
  end

  before(:each) do
    # clean up all references from index node
    puts "Neo4j::IndexNode.instance.relationships= #{Neo4j::IndexNode.instance.relationships}"
    Neo4j::IndexNode.instance.relationships.outgoing.each {|r| r.delete}
  end
  
  it "has a reference to a created node" do
    #should only have a reference to the reference node
    n = RefTestNode.new
    n.name = 'hoj'

    # then
    Neo4j::IndexNode.instance.relationships.nodes.should include(n)
    Neo4j::IndexNode.instance.relationships.to_a.size.should == 1
  end

  it "has a reference to all created nodes" do
    Neo4j::IndexNode.instance.relationships.outgoing.to_a.should be_empty
    node1 = RefTestNode.new
    node2 = RefTestNode2.new
    node3 = RefTestNode2.new

    # then
    Neo4j::IndexNode.instance.relationships.outgoing(:RefTestNode).nodes.should include(node1)
    Neo4j::IndexNode.instance.relationships.outgoing(:RefTestNode2).nodes.should include(node2, node3)
    Neo4j::IndexNode.instance.relationships.outgoing(:RefTestNode).nodes.to_a.size.should == 1
    Neo4j::IndexNode.instance.relationships.outgoing(:RefTestNode2).nodes.to_a.size.should == 2

    RefTestNode.all.nodes.to_a.size.should == 1
    RefTestNode2.all.nodes.to_a.size.should == 2
  end

  it "can allow to create my own relationships (with has_n,has_one) from the reference node" do
    node = RefTestNode.new
    node.name = "ojoj"
  
    # when
    Neo4j.ref_node.class.has_one :my_node
  
    # then
    Neo4j.ref_node.my_node = node
    Neo4j.ref_node.my_node.should == node
    Neo4j.ref_node.my_node.name.should == "ojoj"
  end

end

