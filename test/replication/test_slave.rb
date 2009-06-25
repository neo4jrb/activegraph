$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/extensions/rest_slave'

#
# This example creates a little neo database that the test_slave can synchronize agains
#

Neo4j.start
Neo4j.replicate
Neo4j.stop

puts "Has replicated master neo database"
puts "start irb and type"
puts "  require 'neo4j'"
puts "  Neo4j.start"
puts "  Neo4j::Transaction.new"
puts "  a = Neo4j.load(3)"
puts "  b = Neo4j.load(5)"
puts "  a.relationship?(:foo) #=> true"

