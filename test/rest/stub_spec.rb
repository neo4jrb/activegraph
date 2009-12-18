$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/extensions/rest'

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


describe 'Neo4j::Rest::RestStub' do
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

  it "should wrap the reference node as a NodeStub" do
    stub = Neo4j::Rest::NodeStub.new("http://0.0.0.0:9123/nodes/ReferenceNode/0")
    stub[:id].should == 0
    stub[:classname] == "Neo4j::ReferenceNode"
  end


  it "should treat the /neo resource as a Node" do
    stub = Neo4j::Rest::NodeStub.new("http://0.0.0.0:9123/neo")
    stub[:ref_node].should == 'http://0.0.0.0:9123/nodes/Neo4j::ReferenceNode/0'
  end


  it "should wrap a newly created node as a NodeStub object" do
    Neo4j::Transaction.new
    a = Neo4j::Node.new
    a[:name] = 'kalle'
    Neo4j::Transaction.finish

    stub = Neo4j::Rest::NodeStub.new(a._uri)
    stub[:id].should == a.neo_id
    stub[:classname].should == "Neo4j::Node"
    stub[:name].should == 'kalle'
  end


  it "should return all rels on NodeStub#relationship" do
    Neo4j::Transaction.new
    a = Neo4j::Node.new
    a[:name] = 'a'
    b = Neo4j::Node.new
    b[:name] = 'b'
    c = Neo4j::Node.new
    c[:name] = 'c'
    d = Neo4j::Node.new
    d[:name] = 'd'
    a.rels.outgoing(:foo) << b
    a.rels.outgoing(:foo) << c
    a.rels.outgoing(:bar) << d
    Neo4j::Transaction.finish

    stub = Neo4j::Rest::NodeStub.new(a._uri)
    stub.rels.each {|r| r.should be_kind_of(Neo4j::Rest::RelationshipStub)}
  end


  it "should return only selected rels on NodeStub#relationship.outgoing('type')" do
    Neo4j::Transaction.new
    a = Neo4j::Node.new
    a[:name] = 'a'
    b = Neo4j::Node.new
    b[:name] = 'b'
    c = Neo4j::Node.new
    c[:name] = 'c'
    d = Neo4j::Node.new
    d[:name] = 'd'
    a.rels.outgoing(:foo) << b
    a.rels.outgoing(:foo) << c
    a.rels.outgoing(:bar) << d
    Neo4j::Transaction.finish

    stub = Neo4j::Rest::NodeStub.new(a._uri)
    nodes = [*stub.rels.outgoing(:foo).nodes]
    nodes.size.should == 2
    nodes[0][:name].should == 'b'
    nodes[1][:name].should == 'c'
  end

  it "should return all nodes on NodeStub#relationship.nodes" do
    Neo4j::Transaction.new
    a = Neo4j::Node.new
    a[:name] = 'a'
    b = Neo4j::Node.new
    b[:name] = 'b'
    c = Neo4j::Node.new
    c[:name] = 'c'
    d = Neo4j::Node.new
    d[:name] = 'd'
    a.rels.outgoing(:foo) << b
    a.rels.outgoing(:foo) << c
    a.rels.outgoing(:bar) << d
    Neo4j::Transaction.finish

    stub = Neo4j::Rest::NodeStub.new(a._uri)
    stub.rels.nodes.each {|r| r.should be_kind_of(Neo4j::Rest::NodeStub)}
  end

end
