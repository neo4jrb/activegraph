require '../admin'
require 'spec'

require 'spec/interop/test'
require 'sinatra/test'

describe 'Neo4j Admin Suite' do
  include Sinatra::Test
  it "should serve the css" do
    port = Sinatra::Application.port # we do not know it since we have not started it - mocked
    # when
    get "/neo4j.css"

    # then
    status.should_not == 404
  end
  it "should serve the index file" do
    port = Sinatra::Application.port # we do not know it since we have not started it - mocked
    # when
    get "/"

    # then
    status.should_not == 404
  end

end