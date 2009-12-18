$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/extensions/rest_master'

#
# This example creates a little neo database that the test_slave can synchronize agains
#

Neo4j.start

Neo4j::Transaction.new
a = Neo4j::Node.new
b = Neo4j::Node.new
a[:name] = 'a'
b[:name] = 'b'
a.rels.outgoing(:foo) << b

Neo4j::Transaction.finish


Neo4j::Rest::RestServer.thread.join