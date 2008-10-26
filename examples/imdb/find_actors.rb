require "rubygems" 
require "neo4j"

require "model"

Neo4j::Neo.instance.start


Neo4j::Transaction.run do
  result = Actor.find(:name => "Willis, Bruce")

  puts "Found #{result.size}"
  willis = result[0]

  puts "Willis, Bruce has acted in: "
  #willis.relations.incoming.each {|r| puts "In: #{r}"}
  #willis.relations.incoming.nodes.each {|r| puts "In: #{r.title}"}
  willis.relations.outgoing.each {|r| puts "Out: #{r.to_s}" }
  willis.relations.outgoing.nodes.each {|n| puts "Out: #{n.title}" }
  willis.acted_in do |movie|
    puts "Movie #{movie.title}"
  end
end

Neo4j::Neo.instance.stop