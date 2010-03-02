IMDB_FILE = 'data/test-actors.list'

Neo4j.migration 1, "Create DB by parsing IMDB file" do
  up do
    puts "Migration 1, processing #{IMDB_FILE} file ..."
    Neo4j::Transaction.run do
      movies = {}
      current_actor = nil
      actors = 0
      no_films = 0

      File.open(IMDB_FILE).each_line do |line|
        next if line.strip.empty?

        tab_items = line.split("\t")

        unless tab_items.empty?
          if !tab_items[0].empty?
            current_actor = Actor.new
            current_actor.name = tab_items.shift.strip
            actors += 1
#            puts "Parse new actor no. #{actors} '#{current_actor.name}'"
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
#            puts "Created new film #{film}"
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
  end

  down do
    puts "deleting all movies and actors"
    Neo4j::Transaction.run do
      Actor.all.each {|a| a.del}
      Movie.all.each {|m| m.del}
    end
  end
end
