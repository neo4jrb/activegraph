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

def reset_and_config_neo4j
  Lucene::Config[:storage_path] = Dir::tmpdir + "/lucene"
  Lucene::Config[:store_on_file] = true
  Neo4j::Config[:rest_port] = 4567
  Neo4j::Config[:storage_path] = Dir::tmpdir + "/neo_storage"
  FileUtils.rm_rf Neo4j::Config[:storage_path]  # NEO_STORAGE
  FileUtils.rm_rf Lucene::Config[:storage_path] unless Lucene::Config[:storage_path].nil?
end

include Rack::Test::Methods

describe 'Restful' do

  def app
    Sinatra::Application
  end


  before(:each) do
    Neo4j.stop
    reset_and_config_neo4j
    Neo4j.start
    Neo4j::Transaction.new
    
    class RestPerson
      include Neo4j::NodeMixin
      # by including the following mixin we will expose this node as a RESTful resource
      include Neo4j::RestMixin
      property :name
      index :name
      has_n :friends
    end

    class SomethingElse
      include Neo4j::NodeMixin
      include Neo4j::RestMixin
      property :name
      index :name, :tokenized => true
      has_one :best_friend
    end

    class MyNode
      include Neo4j::NodeMixin
      include Neo4j::RestMixin
    end
  end


  it "should support POST ruby code on /neo" do
    (defined? FooRest).should_not == "constant"

    code = <<END_OF_STRING
class FooRest
include Neo4j::NodeMixin
include Neo4j::RestMixin
property :name
end
END_OF_STRING

    # when
    post "/neo", code

    # then
    last_response.status.should == 200
    (defined? FooRest).should == "constant"
  end


  it "should contain a reference to the ref_node on GET /neo" do
    # when
    get '/neo'

    # then
    last_response.status.should == 200
    body = JSON.parse(last_response.body)
    body['properties']['ref_node'].should == 'http://0.0.0.0:4567/nodes/Neo4j::ReferenceNode/0'
  end


  it "should return the location of the reference node on GET /neo" do

    # when
    get '/neo'

    # then
    last_response.status.should == 200
    body = JSON.parse(last_response.body)
    body['ref_node'] == 'http://0.0.0.0:4567/nodes/Neo4j::ReferenceNode/0'
  end

  it "should know the URI of a RestPerson instance" do
    p = RestPerson.new
    port = Sinatra::Application.port # we do not know it since we have not started it - mocked
    p._uri.should == "http://0.0.0.0:#{port}/nodes/RestPerson/#{p.neo_id}"
  end

  it "should traverse a relationship on depth 1 - e.g. GET nodes/RestPerson/<id>/traverse?relationship=friends&depth=1" do
    # the reference node has id = 0; the index node has id = 1
    adam = RestPerson.new # id = 2
    adam.name = 'adam'

    bertil = RestPerson.new # id = 3
    bertil.name = 'bertil'

    carl = RestPerson.new # id = 4

    adam.friends << bertil << carl

    # when
    get "/nodes/RestPerson/#{adam.neo_id}/traverse?relationship=friends&depth=1"

    # then
    last_response.status.should == 200
    body = JSON.parse(last_response.body)
    body['uri_list'].should_not be_nil
    body['uri_list'][0].should == 'http://0.0.0.0:4567/nodes/RestPerson/3' # bertil
    body['uri_list'][1].should == 'http://0.0.0.0:4567/nodes/RestPerson/4' # carl
    body['uri_list'].size.should == 2
  end

  it "should traverse a relationship depth all - e.g. GET nodes/RestPerson/<id>/traverse?relationship=friends&depth=all" do
    # the reference node has id = 0; the index node has id = 1
    adam = RestPerson.new # id = 2
    adam.name = 'adam'

    bertil = RestPerson.new # id = 3
    bertil.name = 'bertil'

    carl = RestPerson.new # id = 4

    adam.friends << bertil
    bertil.friends << carl

    # when
    get "/nodes/RestPerson/#{adam.neo_id}/traverse?relationship=friends&depth=all"

    # then
    last_response.status.should == 200
    body = JSON.parse(last_response.body)
    body['uri_list'].should_not be_nil
    body['uri_list'][0].should == 'http://0.0.0.0:4567/nodes/RestPerson/3' # bertil
    body['uri_list'][1].should == 'http://0.0.0.0:4567/nodes/RestPerson/4' # carl
    body['uri_list'].size.should == 2
  end

  it "should receive a 400 error code if the depth parameter is not an integer on the traverse resource" do
    get "/nodes/RestPerson/#{RestPerson.new.neo_id}/traverse?relationship=friends&depth=oj"

    # then
    last_response.status.should == 400
  end

  it "should create declared relationship on POST /nodes/RestPerson/friends" do
    adam = RestPerson.new
    adam.name = 'adam'

    bertil = RestPerson.new
    bertil.name = 'bertil'
    bertil.friends << RestPerson.new

    # when
    post "/nodes/RestPerson/#{adam.neo_id}/friends", { :uri => bertil._uri }.to_json

    # then
    last_response.status.should == 201
    # rel ID 0 = reference node to index node
    # rel ID 1 = index node to adam
    # rel ID 2 = index node to bertil
    # rel ID 3 = index node to unnamed
    # rel ID 4 = bertil to unnamed
    # rel ID 5 = adam to bertil (the one we just created)
    last_response.location.should == "/rels/5"
    adam.friends.should include(bertil)
  end

  it "should create an undeclared relationship on POST /nodes/<classname>/<any relationship type>" do
    # given two Nodes that has an undeclared relationship

    node1 =MyNode.new
    node2 = MyNode.new

    # when
    post "#{node1._uri_rel}/fooz", { :uri => node2._uri }.to_json

    # then
    last_response.status.should == 201
    node1.rels.outgoing(:fooz).nodes.should include(node2)
  end

  it "should list related nodes on GET /nodes/RestPerson/<node_id>/friends" do
    adam = RestPerson.new
    adam.name = 'adam'
    bertil = RestPerson.new
    bertil.name = 'bertil'
    adam.friends << bertil

    # when
    get "/nodes/RestPerson/#{adam.neo_id}/friends"

    # then
    last_response.status.should == 200
    body = JSON.parse(last_response.body)
    body.size.should == 1
    body[0]['_neo_id'].should == bertil.neo_id
  end

  it "should return a single related node on GET /nodes/<classname>/<node_id>/<has_one_rel>" do
    adam = SomethingElse.new
    adam.name = 'adam'
    bertil = RestPerson.new
    bertil.name = 'bertil'
    adam.best_friend = bertil

    # when
    get "/nodes/RestPerson/#{adam.neo_id}/best_friend"

    # then
    last_response.status.should == 200
    body = JSON.parse(last_response.body)
    body['_neo_id'].should == bertil.neo_id
  end

  it "should be possible to load a rels on GET /rels/<id>" do
    # the reference node has id = 0; the index node has id = 1
    adam = RestPerson.new # id = 2
    bertil = RestPerson.new # id = 3
    rel = adam.friends.new(bertil)
    rel[:foo] = 'bar'

    # when
    get "/rels/#{rel.neo_id}"

    # then
    last_response.status.should == 200
    body = JSON.parse(last_response.body)
    body['properties']['foo'].should == 'bar'
    body['end_node']['uri'].should == 'http://0.0.0.0:4567/nodes/RestPerson/3' # bertil
    body['start_node']['uri'].should == 'http://0.0.0.0:4567/nodes/RestPerson/2' # adam
  end


  it "should create a new RestPerson on POST /nodes/RestPerson" do
    data = {:properties => { :name => 'kalle'} }

    # when
    post '/nodes/RestPerson', data.to_json

    # then
    last_response.status.should == 201
    last_response.location.should == "http://0.0.0.0:4567/nodes/RestPerson/2" # 0 is ref node, 1 is index node
  end

  it "should persist a new RestPerson created by POST /nodes/RestPerson" do
    data = {:properties => { :name => 'kalle'} }

    # when
    Neo4j::Transaction.finish # run the post outside of a transaction
    Neo4j::Transaction.running?.should == false
    post '/nodes/RestPerson', data.to_json
    location = last_response["Location"]
    get location

    # then
    last_response.status.should == 200
    body = JSON.parse(last_response.body)
    body['properties']['name'].should == 'kalle'
  end

  it "should have a location header in the response for a POST on /nodes/RestPerson" do
    data = {:properties => { :name => 'kalle'} }

    # when
    post '/nodes/RestPerson', data.to_json
    location = last_response["Location"]
    get location

    # then
    last_response.status.should == 200
    body = JSON.parse(last_response.body)
    body['properties']['name'].should == 'kalle'
  end

  it "should find a RestPerson on GET /nodes/RestPerson/<id>" do
    # given
    p = RestPerson.new
    p.name = 'sune'

    # when
    get "/nodes/RestPerson/#{p.neo_id}"

    # then
    last_response.status.should == 200
    data = JSON.parse(last_response.body)
    data['properties'].should include("name")
    data['properties']['name'].should == 'sune'
  end


  it "should contain hyperlinks to its relationships on found nodes" do
    # given         # rel ID 0: reference node -> index node
    n1 = MyNode.new # rel ID 1: index -> n1
    n2 = MyNode.new # rel ID 2: index -> n2
    n3 = MyNode.new # rel ID 3: index -> n3
    n4 = MyNode.new # rel ID 4: index -> n4

    n1.rels.outgoing(:type1) << n2 # rel ID 5
    n1.rels.outgoing(:type2) << n3 # rel ID 6
    n1.rels.outgoing(:type2) << n4 # rel ID 7

    # when
    get "/nodes/MyNode/#{n1.neo_id}"

    # then
    last_response.status.should == 200
    data = JSON.parse(last_response.body)
    data['rels'].should_not be_nil
    data['rels']['type1'].should_not be_nil
    data['rels']['type2'].should_not be_nil
    data['rels']['type2'].should include('http://0.0.0.0:4567/rels/6')
    data['rels']['type2'].should include('http://0.0.0.0:4567/rels/7')
    data['rels']['type1'].should include('http://0.0.0.0:4567/rels/5')
  end


  it "should return a 404 if it can't find the node" do
    get "/nodes/RestPerson/742421"

    # then
    last_response.status.should == 404
  end

  it "should set all properties on PUT nodes/RestPerson/<node_id>" do
    # given
    p = RestPerson.new
    p.name = 'sune123'
    p[:some_property] = 'foo'

    # when
    data = {:properties => {:name => 'blah', :dynamic_property => 'cool stuff'} }
    put "/nodes/RestPerson/#{p.neo_id}", data.to_json

    # then
    last_response.status.should == 200
    p.name.should == 'blah'
    p[:some_property].should be_nil
    p[:dynamic_property].should == 'cool stuff'
  end

  it "should delete a node on DELETE nodes/RestPerson/<node_id>" do
    # given
    p = RestPerson.new
    p.name = 'asdf'
    id = p.neo_id

    # when
    delete "/nodes/RestPerson/#{id}"
    Neo4j::Transaction.current.success # delete only takes effect when transaction has ended
    Neo4j::Transaction.new
    Neo4j::Transaction.finish

    # then
    last_response.status.should == 200
    Neo4j::Transaction.run {Neo4j.load_node(id).should be_nil}
  end

  it "should get property on GET nodes/RestPerson/<node_id>/<property_name>" do
    # given
    p = RestPerson.new
    p.name = 'sune123'

    # when
    get "/nodes/RestPerson/#{p.neo_id}/name"

    # then
    last_response.status.should == 200
    data = JSON.parse(last_response.body)
    data['name'].should == 'sune123'
  end

  it "should set property on PUT nodes/RestPerson/<node_id>/<property_name>" do
    # given
    p = RestPerson.new
    p.name = 'sune123'

    # when
    data = { :name => 'new-name'}
    put "/nodes/RestPerson/#{p.neo_id}/name", data.to_json

    # then
    last_response.status.should == 200
    p.name.should == 'new-name'
  end

  it "should return all nodes of that class type on GET /nodes/RestPerson" do
    # given
    p1 = RestPerson.new
    p1.name = 'p1'
    p2 = RestPerson.new
    p2.name = 'p2'
    e = SomethingElse.new
    e.name = 'p3'
    Neo4j::Transaction.finish

    # when
    get "/nodes/RestPerson"

    # then
    last_response.status.should == 200
    data = JSON.parse(last_response.body)
    data.size.should == 2
    data.map{|p| p['name']}.should include("p1")
    data.map{|p| p['name']}.should include("p2")
  end

  it "should search for exact property matches on GET /nodes/RestPerson?name=p" do
    # given
    p1 = RestPerson.new
    p1.name = 'p'
    p1_id = p1.neo_id
    p2 = RestPerson.new
    p2.name = 'p2'
    Neo4j::Transaction.current.success # ensure index gets updated
    Neo4j::Transaction.finish

    # when
    get "/nodes/RestPerson?name=p"

    # then
    last_response.status.should == 200
    data = JSON.parse(last_response.body)
    data.size.should == 1
    data[0]['_neo_id'].should == p1_id
    data[0]['name'].should == "p"
  end

  it "should sort by property value on GET /nodes/RestPerson?sort=name,desc" do
    # given
    p1 = RestPerson.new
    p1.name = 'p1'
    p2 = RestPerson.new
    p2.name = 'p2'
    Neo4j::Transaction.finish

    Neo4j::Transaction.run {
    Neo4j.load_node(2).should_not be_nil
                            }
    # when
    get "/nodes/RestPerson?sort=name,desc"

    # then
    last_response.status.should == 200
    data = JSON.parse(last_response.body)
    data.size.should == 2
    data[0]['name'].should == "p2"
    data[1]['name'].should == "p1"
  end

  it "should not blow up when sorting when there is no data" do
    # when
    get "/nodes/RestPerson?sort=name"
    # then
    last_response.status.should == 200
    JSON.parse(last_response.body).size.should == 0
  end

  it "should treat GET /nodes/SomethingElse?search=... as a Lucene query string" do
    # given
    p1 = SomethingElse.new
    p1.name = 'the supplier'
    p2 = SomethingElse.new
    p2.name = 'the customer'
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    # when
    get "/nodes/SomethingElse?search=name:cutsomer~" # typo to test fuzzy matching

    # then
    last_response.status.should == 200
    data = JSON.parse(last_response.body)
    data.size.should == 1
    data[0]['name'].should == "the customer"
  end

  it "should return a subset of nodes on GET /nodes/RestPerson?limit=50,10" do
    # given
    100.times{|n| RestPerson.new.name = 'p' + sprintf('%02d', n) }
    Neo4j::Transaction.current.success # ensure index gets updated
    Neo4j::Transaction.finish

    # when
    get "/nodes/RestPerson?sort=name,desc&limit=50,10"

    # then
    last_response.status.should == 200
    data = JSON.parse(last_response.body)
    data.size.should == 10
    data.map{|p| p['name']}.should == %w(p49 p48 p47 p46 p45 p44 p43 p42 p41 p40)
  end

  it "should find nodes even if they have no properties" do
    # given
    id = RestPerson.new.neo_id
    Neo4j::Transaction.current.success # ensure index gets updated
    Neo4j::Transaction.finish

    # when
    get "/nodes/RestPerson"

    # then
    last_response.status.should == 200
    data = JSON.parse(last_response.body)
    data.size.should == 1
    data[0]['_neo_id'].should == id
  end
end


#describe 'Restful Hyperlinks between Neo4j resources' do
#  include Rack::Test::Methods
#
#
#  def app
#    Sinatra::Application
#  end
#
#  before(:all) do
#    reset_and_config_neo4j
#  end
#
#  after(:all) do
#    Neo4j::Transaction.finish if Neo4j::Transaction.running?
#    Neo4j.stop
#  end
#
#
#  it "should expose the TxNodeList as a REST Resource" do
#    pending
#    # navigate to reference node
#    get '/nodes/Neo4j::ReferenceNode/0'
#    body = JSON.parse(last_response.body)
#
#    # navigate to relationship tx_node_list
#    get body['rels']['tx_node_list']
#    last_response.status.should == 200
#    body = JSON.parse(last_response.body)
#    body['end_node'].should_not be_nil
#
#    # navigate to end node of that relationship
#    get body['end_node']['uri']
#    last_response.status.should == 200
#
#    # we should now come to the TxNodeList
#    body = JSON.parse(last_response.body)
#    last_response.status.should == 200
#    body['properties']['classname'].should == "Neo4j::TxNodeList"
#  end
#end