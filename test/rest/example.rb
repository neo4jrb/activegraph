$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
require 'neo4j'
require 'neo4j/extensions/rest'


# THIS DOES NOT WORK WITH SINATRA 0.9.2 but it works with the latest sinatra from github
class Person
  include Neo4j::NodeMixin
  # by includeing the following mixin we will expose this node as a RESTful resource
  include RestMixin
  property :name
  has_n :friends
end


Neo4j::Transaction.run { Person.new.name = "andreas"}
Neo4j.start
#puts "HOST " + Sinatra::Application.host
#Sinatra::Application.run! :port => 9123
