# Usage: rails new myapp -m neo4j.rb -O

gem "neo4j", '~> 3.0.0'


generator = %q[
    config.generators do |g|
      g.orm             :neo4j
    end

    # Configure where the embedded neo4j database should exist
    # Notice embedded db is only available for JRuby
    # config.neo4j.session_type = :embedded_db  # default #server_db
    # config.neo4j.session_path = File.expand_path('neo4j-db', Rails.root)
]

application generator
inject_into_file 'config/application.rb', "\nrequire 'neo4j/railtie'", :after => 'require "sprockets/railtie"'

