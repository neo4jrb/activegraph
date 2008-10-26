require "rubygems" 
require "neo4j"
require "model"

def parse_actors(file)
  movies = {}
  current_actor = nil
  actors = 0
  no_films = 0
  
  File.open(file).each_line do |line|
    next if line.strip.empty?

    tab_items = line.split("\t")
  
    unless tab_items.empty?
      if !tab_items[0].empty?
        current_actor = Actor.new
        current_actor.name = tab_items.shift.strip
        actors += 1
      end
      tab_items.shift
    
      film = tab_items.shift.strip

      # already created film ?
      movie = movies[film]
      if (movie.nil?)
        movie = Movie.new
        movie.title = film
        movie.year = /\((\d+)(\/.)?\)/.match(film)[1]
        movies[film] = movie
        puts "Created new film #{film}"
        no_films += 1
      end

      role = tab_items.shift
      roleNode = current_actor.acted_in.new(movie)
      
      unless (role.nil?)
        role.strip!
        # remove []
        role.slice!(0)
        role.chop!
        title, character = role.split('-')
        roleNode.title = title.strip unless title.nil?
        roleNode.character = character.strip unless character.nil?
      end

      #puts "Actor: '#{current_actor}' Film '#{film}' Year '#{year}' Title '#{title}' Character '#{character}'"
    end
  end
  puts "created #{actors} actors and #{no_films} films"
end


Neo4j::Neo.instance.start


parse_actors('data/test-actors.list')


Neo4j::Neo.instance.stop