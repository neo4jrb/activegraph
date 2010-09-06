$LOAD_PATH.unshift File.join(File.dirname(__FILE__))
require 'spec_helper'


describe Neo4j::Node, "Index" do
  before(:all) { FileUtils.rm_rf Neo4j.config[:storage_path]; FileUtils.mkdir_p(Neo4j.config[:storage_path]) }
  after(:all) { Neo4j.shutdown }


  it "index a node" do
    Neo4j::Transaction.new
    new_node = Neo4j::Node.new
    new_node[:name] = 'Andreas Ronge'

    # when
    new_node.index(:name)
    Neo4j::Transaction.finish

    # then
    Neo4j::Node.find(:name, 'Andreas Ronge').first.should == new_node

  end
end