#####################################
#
# IMPORTANT
#
# This test requires the latest version from GITHUB of the 
# rack-test 7ae931bb7c1d234a657fe7b32b562f4084696975 (from  Sat Jun 13 15:42:49 2009 -0400)
# git clone git://github.com/brynary/rack-test.git
# cd rack-test
# rake install
#
# And the following GEMS:
#   json-jruby (1.1.6)
#   rack (1.0.0)
#   rake (0.8.7)
#   rspec (1.2.6)
#   sinatra (0.9.2)


$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/extensions/rest'

require 'spec'
require 'spec/interop/test'
require 'rack/test'


# TODO refactor, duplicated code in spec_helper
#require 'neo4j/spec_helper'

require 'fileutils'
require 'tmpdir'

# suppress all warnings
$NEO_LOGGER.level = Logger::ERROR
NEO_STORAGE = Dir::tmpdir + "/neo_storage"
LUCENE_INDEX_LOCATION = Dir::tmpdir + "/lucene"
Lucene::Config[:storage_path] = LUCENE_INDEX_LOCATION
Lucene::Config[:store_on_file] = false
Neo4j::Config[:storage_path] = NEO_STORAGE


def undefine_class(*clazz_syms)
  clazz_syms.each do |clazz_sym|
    Object.instance_eval do
      begin
        #Neo4j::Indexer.remove_instance const_get(clazz_sym)
        remove_const clazz_sym
      end if const_defined? clazz_sym
    end
  end
end


Sinatra::Application.set :environment, :test

describe 'Restful' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before(:all) do
    debug_mode = true
    NEO_STORAGE = Dir::tmpdir + "/neo_storage"
    LUCENE_INDEX_LOCATION = Dir::tmpdir + "/lucene"
    Lucene::Config[:storage_path] = LUCENE_INDEX_LOCATION
    Lucene::Config[:store_on_file] = false
    Neo4j::Config[:storage_path] = NEO_STORAGE
    FileUtils.rm_rf Neo4j::Config[:storage_path]  # NEO_STORAGE
    FileUtils.rm_rf Lucene::Config[:storage_path] unless Lucene::Config[:storage_path].nil?
    Neo4j.event_handler.remove_all
  end


  before(:each) do
    Neo4j.start
    Neo4j::Transaction.new
    undefine_class :Person
    class Person
      include Neo4j::NodeMixin
      # by including the following mixin we will expose this node as a RESTful resource
      include RestMixin
      property :name
      has_n :friends
    end
  end

  after(:each) do
    Neo4j::Transaction.finish
    Neo4j.stop
    FileUtils.rm_rf Neo4j::Config[:storage_path]  # NEO_STORAGE
    FileUtils.rm_rf Lucene::Config[:storage_path] unless Lucene::Config[:storage_path].nil?
  end

  it "should support POST ruby code on /neo" do
    code = <<END_OF_STRING
class Foo
include Neo4j::NodeMixin
include RestMixin
property :name
puts "DEFINED KLASS"
end
END_OF_STRING

    # when
    post "/neo", code

    # then
    last_response.status.should == 200
    (defined? Foo).should == "constant"
  end


  it "should know the URI of a Person instance" do
    person = Person.new
    port = Sinatra::Application.port # we do not know it since we have not started it - mocked
    person._uri.should == "http://0.0.0.0:#{port}/nodes/Person/#{person.neo_node_id}"
  end

  it "should be possible to traverse a relationship on GET nodes/Person/<id>/traverse?relation=friends&depth=1" do
    adam = Person.new
    adam.name = 'adam'

    bertil = Person.new
    bertil.name = 'bertil'

    carl = Person.new

    adam.friends << bertil << carl

    # when
    get "/nodes/Person/#{adam.neo_node_id}/traverse?relation=friends&depth=1"

    # then
    last_response.status.should == 200
    body = JSON.parse(last_response.body)
    body['uri_list'].should_not be_nil
    body['uri_list'][0].should == 'http://0.0.0.0:4567/nodes/Person/2'
    body['uri_list'][1].should == 'http://0.0.0.0:4567/nodes/Person/3'
    body['uri_list'].size.should == 2
  end

  it "should create a relationship on POST /nodes/Person/friends" do
    adam = Person.new
    adam.name = 'adam'
    bertil = Person.new
    bertil.name = 'bertil'
    bertil.friends << Person.new


    # when
    post "/nodes/Person/#{adam.neo_node_id}/friends", { :uri => bertil._uri }.to_json

    # then
    last_response.status.should == 201
    last_response.location.should == "/relations/1" # starts counting from 0
    adam.friends.should include(bertil)
  end

  it "should list related nodes on GET /nodes/Person/friends" do
    adam = Person.new
    adam.name = 'adam'
    bertil = Person.new
    bertil.name = 'bertil'
    adam.friends << bertil

    # when
    get "/nodes/Person/#{adam.neo_node_id}/friends"

    # then
    last_response.status.should == 200
    body = JSON.parse(last_response.body)
    body.size.should == 1
    body[0]['id'].should == bertil.neo_node_id
  end

  it "should be possible to load a relationship on GET /relations/<id>" do
    adam = Person.new
    bertil = Person.new
    rel = adam.friends.new(bertil)
    rel.set_property("foo", "bar")
    # when
    get "/relations/#{rel.neo_relationship_id}"

    # then
    last_response.status.should == 200
    body = JSON.parse(last_response.body)
    body['foo'].should == 'bar'
  end


  it "should create a new Person on POST /nodes/Person" do
    data = { :name => 'kalle'}

    # when
    post '/nodes/Person', data.to_json

    # then
    last_response.status.should == 201
    last_response.location.should == "/nodes/Person/1"
  end

  it "should be possible to follow the location HTTP header when creating a new Person" do
    data = { :name => 'kalle'}

    # when
    post '/nodes/Person', data.to_json
    puts "LAST RESPONSE=" + last_response.status.to_s
    puts "REPONSE #{last_response['Location']}"
    location = last_response["Location"]
    # follow_redirect! does not work for 201 POST request with only Location header set

    # then
    get location
    last_response.status.should == 200
    body = JSON.parse(last_response.body)
    body['name'].should == 'kalle'
  end

  it "should find a Person on GET /nodes/Person/<neo_node_id>" do
    # given
    p = Person.new
    p.name = 'sune'

    # when
    get "/nodes/Person/#{p.neo_node_id}"

    # then
    last_response.status.should == 200
    data = JSON.parse(last_response.body)
    data.should include("name")
    data['name'].should == 'sune'
  end

  it "should return a 404 if it can't find the node" do
    get "/nodes/Person/742421"

    # then
    last_response.status.should == 404
  end

  it "should be possible to set all properties on PUT nodes/Person/<node_id>" do
    # given
    p = Person.new
    p.name = 'sune123'
    p[:some_property] = 'foo'

    # when
    data = {:name => 'blah', :dynamic_property => 'cool stuff'}
    put "/nodes/Person/#{p.neo_node_id}", data.to_json

    # then
    last_response.status.should == 200
    p.name.should == 'blah'
    p.props['some_property'].should be_nil
    p.props['dynamic_property'].should == 'cool stuff'
  end

  it "should be possible to delete a node on DELETE nodes/Person/<node_id>" do
    # given
    p = Person.new
    p.name = 'asdf'
    id = p.neo_node_id

    # when
    delete "/nodes/Person/#{id}"

    # then
    last_response.status.should == 200
    # we have to finish the transaction before the node is actually deleted
    Neo4j::Transaction.finish
    Neo4j::Transaction.new
    Neo4j.load(id).should be_nil
  end

  it "should be possible to get a property on GET nodes/Person/<node_id>/<property_name>" do
    # given
    p = Person.new
    p.name = 'sune123'

    # when
    get "/nodes/Person/#{p.neo_node_id}/name"

    # then
    last_response.status.should == 200
    data = JSON.parse(last_response.body)
    data['name'].should == 'sune123'
  end

  it "should be possible to set a property on PUT nodes/Person/<node_id>/<property_name>" do
    # given
    p = Person.new
    p.name = 'sune123'

    # when
    data = { :name => 'new-name'}
    put "/nodes/Person/#{p.neo_node_id}/name", data.to_json

    # then
    last_response.status.should == 200
    p.name.should == 'new-name'
  end
end