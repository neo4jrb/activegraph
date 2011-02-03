require 'movie'

puts "Neo4j Version #{Neo4j::VERSION}"

def find_actor(query_or_id)
  id           = query_or_id.to_i
  lucene_query = id == 0 && query_or_id
  
  if lucene_query
    result = Actor.find(lucene_query)
    puts "Found #{result.size} actors"
    result.each { |x| puts x }
  else
    actor = Neo4j::Node.load(id)
    puts "No Actor found with id #{id}" if actor.nil?
    puts "Loaded node not an actor, it is an #{actor.class}" unless actor.class == Actor
    return if actor.nil? || actor.class != Actor

    puts actor
    puts "  Acted in #{actor.acted_in_rels.to_a.size} movies"
    actor.acted_in_rels.each do |rel|
      puts "    #{rel} #{rel.end_node}"
    end
  end
end

def find_movies(query_or_id)
  id           = query_or_id.to_i
  lucene_query = id == 0 && query_or_id

  if lucene_query
    result = Movie.find(lucene_query)
    puts "Found #{result.size} Movies"
    result.each { |x| puts x }
  else
    movie = Neo4j::Node.load(id)
    puts "No movier found with id #{id}" if movie.nil?
    puts "Loaded node not an actor, it is an #{movie.class}" unless movie.class == Movie
    return if movie.nil? || movie.class != Movie

    puts movie
    puts "has #{movie.actors.to_a.size} actors"
    movie.actors.each { |a| puts a}
  end
end

def find_roles(query_or_id)
  id           = query_or_id.to_i
  lucene_query = id == 0 && query_or_id

  if lucene_query
    result = Role.find(lucene_query)
    puts "Found #{result.size} Roles"
    result.each { |x| puts "#{x} #{x.start_node} #{x.end_node}" }
  else
    role = Neo4j::Relationship.load(id)
    puts "No role found with id #{id}" if role.nil?
    puts "Loaded node not an Role, it is an #{role.class}" unless role.class == Role
    return if role.nil? || role.class != Role

    puts "Found #{role} #{role.start_node} #{role.end_node}"
  end
end

if (ARGV.size == 1)
  find_actor(ARGV[0])
elsif ARGV.size == 2 && ARGV[0] == "-m"
  find_movies(ARGV[1])
elsif ARGV.size == 2 && ARGV[0] == "-r"
  find_roles(ARGV[1])
else
  puts "Usage: jruby find.rb [-m|-r] <actor name|actor neo_id>\n\n  -m \tfinds the movies for the given a lucene query or an id\n  -r \t same as -m but finds roles\n"
end

Neo4j.shutdown