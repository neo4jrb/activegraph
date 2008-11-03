require "rubygems" 
require "neo4j"

require "model"

Neo4j.start



result = Actor.find(:name => "Willis, Bruce")

puts "Found #{result.size}"
willis = result[0]

puts "Willis, Bruce has acted in: "
willis.relations.outgoing.each {|r| puts r.to_s }

willis.acted_in.each do |movie|
  puts "Movie #{movie.title}"
end

Neo4j.stop