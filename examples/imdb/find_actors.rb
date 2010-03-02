$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
require "rubygems"
require "neo4j"

# we have to configure these before the model is loaded
Lucene::Config[:store_on_file] = true
Lucene::Config[:storage_path] = "tmp/lucene"


require "model"
require "neo4j/extensions/reindexer"


# Keep lucene index on file system instead of in memory


# Load Migrations
# Create Database
require '1_create_neo_db'

# just for fun I have two migrations - first one for importing the database and second for indexing it.
require '2_index_db'

def find_actor(name)
  Neo4j::Transaction.run do
    puts "Find all actors named #{name}"
    result = Actor.find(:name => name)

    puts "Found #{result.size} actors"
    result.each {|x| puts "#{x.neo_id}\t#{x}"}
  end
end

def find_movies(neo_id)
  Neo4j::Transaction.run do
    actor = Neo4j.load_node(neo_id)
    puts "No actor found with neo id #{neo_id}" if actor.nil?
    return if actor.nil?

    puts "#{actor} acted in:"
    actor.acted_in_rels.each {|r| puts "Movie #{r.end_node.title} title: #{r.title}"}
  end
end

Neo4j.start
if (ARGV.size == 1)
  find_actor(ARGV[0])
elsif ARGV.size == 2 && ARGV[0] == "-m"
  find_movies(ARGV[1])
else
  puts "Usage: jruby find_actors.rb [-m] <actor name|actor neo_id>\n\n  -m \tfinds the movies for the given actor neo_id"
end

Neo4j.stop
