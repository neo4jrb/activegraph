$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
require "rubygems" 
require "neo4j"
require "model"

DB_NEO_DIR = File.expand_path(File.dirname(__FILE__) + "/db/neo")
DB_LUCENE_DIR = File.expand_path(File.dirname(__FILE__) + "/db/lucene")

Neo4j.start DB_NEO_DIR #, DB_LUCENE_DIR


Actor.index :name, :tokenized => true
puts "REINDEX ACTORS"
Actor.update_index
puts "Find all actors named willis"
result = Actor.find(:name => "willis") #, Bruce")

puts "Found #{result.size} actors"
result.each {|x| puts x}

willis = result[0]
puts "#{willis} acted in:"
willis.relations.outgoing.each {|r| puts r.to_s }

willis.acted_in.each { |movie| puts movie }

Neo4j.stop
