$LOAD_PATH.unshift File.join(File.dirname(__FILE__))
require 'spec_helper'

describe Neo4j::Node do
  before(:all) { FileUtils.rm_rf Neo4j.config[:storage_path]; FileUtils.mkdir_p(Neo4j.config[:storage_path]) }
  after(:all) { Neo4j.shutdown }

  describe "Create" do
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

  describe "Properties" do
    it "set and get String properties with the [] operator" do
      Neo4j::Transaction.new
      new_node = Neo4j::Node.new
      new_node[:key] = 'myvalue'
      new_node[:key].should == 'myvalue'
      Neo4j::Transaction.finish
    end

    it "set and get Fixnum properties with the [] operator" do
      Neo4j::Transaction.new
      new_node = Neo4j::Node.new
      new_node[:key] = 42
      new_node[:key].should == 42
      Neo4j::Transaction.finish
    end


    it "set and get Float properties with the [] operator" do
      Neo4j::Transaction.new
      new_node = Neo4j::Node.new
      new_node[:key] = 3.1415
      new_node[:key].should == 3.1415
      Neo4j::Transaction.finish
    end

    it "set and get Boolean properties with the [] operator" do
      Neo4j::Transaction.new
      new_node = Neo4j::Node.new
      new_node[:key] = true
      new_node[:key].should == true
      new_node[:key] = false
      new_node[:key].should == false
      Neo4j::Transaction.finish
    end


    it "set and get properties with the [] operator and String key" do
      Neo4j::Transaction.new
      new_node = Neo4j::Node.new
      new_node["a"] = 'foo'
      new_node["a"].should == 'foo'
      Neo4j::Transaction.finish
    end
  end
end