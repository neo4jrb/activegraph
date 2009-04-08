$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
require 'neo4j'
require 'rubygems'
require 'sinatra/base'
#require 'sinatra'

Sinatra::Application.set(:public, File.dirname(__FILE__) + "/public")

Sinatra::Application.get('/') do
  erb :index
end

Sinatra::Application.post('/echo') do
  puts request.body
  request.body
end
Sinatra::Application.post('/jquery.js') do
  puts request.body
  request.body
end

Sinatra::Application.get('/echo') do
  puts request.body
  'pong get'
end
puts "HOST " + Sinatra::Application.host
Sinatra::Application.run! :port => 9123
#Neo4j.start_rest