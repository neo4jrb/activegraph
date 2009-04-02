$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
require 'neo4j'

class Person
  include Neo4j::NodeMixin
  # by includeing the following mixin we will expose this node as a RESTful resource
  include RestMixin
  property :name
  has_n :friends
end

puts "HOST " + Sinatra::Application.host
Sinatra::Application.run! :port => 9123
