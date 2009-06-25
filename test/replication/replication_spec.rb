$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/extensions/rest_master'

require 'spec'
require 'spec/interop/test'
require 'rack/test'
require 'fileutils'
require 'tmpdir'


Sinatra::Application.set :environment, :test

module Neo4j
  module Rest
    module RestHttpMethods
      class << self
        remove_method :_get_request
        include Rack::Test::Methods

        def _get_request(uri, params = {})
          get(uri, params)
          last_response.body
        end

        def app
          Sinatra::Application
        end

      end
    end
  end


  class Node
    include Neo4j::RestMixin
  end

  class ReferenceNode
    include Neo4j::RestMixin
  end
  
end


def reset_and_config_neo4j
  Lucene::Config[:storage_path] = Dir::tmpdir + "/lucene"
  Lucene::Config[:store_on_file] = true
  Neo4j::Config[:storage_path] = Dir::tmpdir + "/neo_storage"
  FileUtils.rm_rf Neo4j::Config[:storage_path]  # NEO_STORAGE
  FileUtils.rm_rf Lucene::Config[:storage_path] unless Lucene::Config[:storage_path].nil?
end


describe 'Restful Navigation from /neo' do
  include Rack::Test::Methods


  def app
    Sinatra::Application
  end

  before(:all) do
    reset_and_config_neo4j
    Neo4j.start
  end

  after(:all) do
    Neo4j::Transaction.finish if Neo4j::Transaction.running?
    Neo4j.stop
  end

  it "should have relationships from reference node to TxNodeList" do
    # when
    stub = Neo4j::Rest::NodeStub.new("http://0.0.0.0:9123/nodes/ReferenceNode/0")
    stub.relationships.outgoing(:tx_node_list).nodes.first[:classname].should == "Neo4j::TxNodeList"
  end

  it "should create a relationship to TxNode from TxNodeList when a node is created" do
    Neo4j::Transaction.new
    a = Neo4j::Node.new
    Neo4j::Transaction.finish

    uri = Neo4j::TxNodeList.instance._uri
    tx_node_list = Neo4j::Rest::NodeStub.new(uri)
    tx_node = tx_node_list.relationships.outgoing(:tx_nodes).nodes.first
    tx_node[:classname].should == 'Neo4j::TxNodeCreated'
    tx_node[:created].should be_true
  end

  it "should recreate a created node" do
    Neo4j::Transaction.new
    a = Neo4j::Node.new
    a[:fooz] = 'abc'
    uuid = a[:uuid]
    Neo4j::Transaction.finish

    # create a pointer to this transaction
    uri = Neo4j::TxNodeList.instance._uri
    tx_node_list = Neo4j::Rest::NodeStub.new(uri)
    tx_node = tx_node_list.relationships.outgoing(:tx_nodes).nodes.first

    puts "curr tx node #{tx_node.props.inspect} uuid #{uuid}"
    Neo4j::Transaction.run { a.delete }
    
    Neo4j::Transaction.new
    Neo4j::TxNodeList.instance.redo_tx(tx_node)
    Neo4j::Transaction.finish

    Neo4j::Transaction.new
    node = Neo4j.load_node_with_uuid(uuid)
    node.should_not be_nil
    node[:uuid].should == uuid
    puts "GOT #{node.neo_node_id}"
    node.neo_node_id.should_not == a.neo_node_id # make sure a new node was created (a duplicate of a)
    node[:fooz].should == 'abc'
    Neo4j::Transaction.finish
  end


  it "should recreate a properties on a node" do
    Neo4j::Transaction.new
    a = Neo4j::Node.new
    uuid = a[:uuid]
    Neo4j::Transaction.finish

    uri = Neo4j::TxNodeList.instance._uri
    tx_node_list = Neo4j::Rest::NodeStub.new(uri)
    tx_node = tx_node_list.relationships.outgoing(:tx_nodes).nodes.first

    Neo4j::Transaction.new
    Neo4j::TxNodeList.instance.redo_tx(tx_node)
    node = Neo4j.load_node_with_uuid(uuid)
    node[:uuid].should == uuid    # make sure it has the same uuid as the duplicated node
    node.neo_node_id.should_not == a.neo_node_id # make sure a new node was created (a duplicate of a)
    Neo4j::Transaction.finish
  end

end