#####################################
#
# A simple example how to expose neo nodes as REST resources.
#
# IMPORTANT
#
# This example requires the latest version from GITHUB of the sinatra gem
# and  json-jruby (>=1.1.6) (or another compatible json gem)
#

$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")
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
  index :name
end

Neo4j.start
puts "-----------------------"
Neo4j::Transaction.run do
  a = Person.new
  b = Person.new
  c = Person.new
  a.name = 'andreas'
  b.name = 'kalle'
  c.name = 'anders'
  a.friends << b
  a[:undeclared] = '123'
  a[:foo] = 3.134
  a.relationships.outgoing(:other) << c
end

puts "Created a person at URI http://localhost:9123/nodes/Person/1"
Neo4j::Rest::RestServer.thread.join

#puts "HOST " + Sinatra::Application.host
#Sinatra::Application.run! :port => 9123
