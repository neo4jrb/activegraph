require 'movie'

# Remove old database if there is one
FileUtils.rm_rf Neo4j::Config[:storage_path]  # this is the default location of the database


IMDB_FILE = 'data/test-actors.list'

movies        = {}
current_actor = nil
actors        = 0
no_films      = 0

inserter = Neo4j::Batch::Inserter.new

File.open(IMDB_FILE).each_line do |line|
  next if line.strip.empty?

  tab_items = line.split("\t")

  unless tab_items.empty?
    if !tab_items[0].empty?
      actor_name = tab_items.shift.strip
      current_actor      = inserter.create_node({'name' => actor_name}, Actor)
      actors             += 1
      puts "Parse new actor no. #{actors} '#{actor_name}' actor_id=#{current_actor}"
    end
    tab_items.shift

    film  = tab_items.shift.strip

    # already created film ?
    movie = movies[film]
    if (movie.nil?)
      movie_title  = film
      movie_year   = /\((\d+)(\/.)?\)/.match(film)[1]
      movie        = inserter.create_node({'title' => movie_title, 'year' => movie_year}, Movie)
      movies[film] = movie
      no_films     += 1
      puts "Created #{no_films} film '#{film}'"
    end

    role     = tab_items.shift
    #roleNode = current_actor.acted_in.new(movie)
    role_props = {}
    unless (role.nil?)
      role.strip!
      # remove []
      role.slice!(0)
      role.chop!
      title, character = role.split('-')
      role_props['title'] = title.strip unless title.nil?
      role_props['character'] = character.strip unless character.nil?
    end
    inserter.create_rel(Actor.acted_in, current_actor, movie, role_props, Role)

#    puts "Actor: '#{current_actor}' Film '#{movie}' Year '#{movie_year}' Title '#{role_props['title']}' Character '#{role_props['character']}'"
  end
end
inserter.shutdown
puts "created #{actors} actors and #{no_films} films"
