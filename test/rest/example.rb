#####################################
#
# IMPORTANT
#
# This example requires the latest version from GITHUB of the sinatra gem
# and  json-jruby (>=1.1.6) (or another compatible json gem)
#


$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
require 'neo4j'
require 'neo4j/extensions/rest'

FileUtils.rm_rf Neo4j::Config[:storage_path]  # NEO_STORAGE
FileUtils.rm_rf Lucene::Config[:storage_path] unless Lucene::Config[:storage_path].nil?


# THIS DOES NOT WORK WITH SINATRA 0.9.2 but it works with the latest sinatra from github
class Person
  include Neo4j::NodeMixin
  # by includeing the following mixin we will expose this node as a RESTful resource
  include Neo4j::RestMixin
  property :name
  has_n :friends
end

Neo4j.start
puts "-----------------------"
Neo4j::Transaction.run { Person.new.name = "andreas"}

puts "Created a person at URI http://localhost:9123/nodes/Person/1"
Neo4j::RestServer.thread.join

#puts "HOST " + Sinatra::Application.host
#Sinatra::Application.run! :port => 9123
