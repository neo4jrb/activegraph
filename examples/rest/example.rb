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
require 'rubygems'
require 'neo4j'
require 'neo4j/extensions/rest'

FileUtils.rm_rf Neo4j::Config[:storage_path]  # NEO_STORAGE
FileUtils.rm_rf Lucene::Config[:storage_path] unless Lucene::Config[:storage_path].nil?


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
  a = Person.new :name => 'andreas', :foo => 'bar', :fav_number => 14
  b = Person.new :name => 'kalle'
  c = Person.new :name => 'anders'
  a.friends << b
  a.rels.outgoing(:other) << c
  puts "Created Nodes at URI:\n\t#{a._uri}\n\t#{b._uri}\n\t#{c._uri}"
end

Neo4j::Rest::RestServer.thread.join
