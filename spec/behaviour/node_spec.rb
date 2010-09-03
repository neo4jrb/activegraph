$LOAD_PATH.unshift File.join(File.dirname(__FILE__))
require 'spec_helper'

describe Neo4j::Node do
  before(:all) {  FileUtils.rm_rf Neo4j.config[:storage_path]; FileUtils.mkdir_p(Neo4j.config[:storage_path]) }
  after(:all) { Neo4j.shutdown }

  it "created node should exist in db after transaction finish" do
    Neo4j::Transaction.new
    new_node = Neo4j::Node.new
    Neo4j::Transaction.finish
    Neo4j::Node.should exist(new_node)
  end

  it "created node should exist in db before transaction finish" do
    Neo4j::Transaction.new
    new_node = Neo4j::Node.new
    Neo4j::Node.should exist(new_node)
    Neo4j::Transaction.finish
  end

end