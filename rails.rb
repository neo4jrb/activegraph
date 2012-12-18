# Usage: rails new myapp -m neo4j.rb -O

NEO4J_VERSION = "2.2.1"

gem_group :development, :test do
  gem "rspec-rails"
end

gem "neo4j", ">= #{NEO4J_VERSION}"
 
# we are using JRuby - use Threads !
gsub_file "config/environments/production.rb", "# config.threadsafe!", "config.threadsafe!"

generator = %q[

    # Enable Neo4j generators, e.g:  rails generate model Admin --parent User
    config.generators do |g|
      g.orm             :neo4j
      g.test_framework  :rspec, :fixture => false
    end

    # Configure where the neo4j database should exist
    config.neo4j.storage_path = "#{config.root}/db/neo4j-#{Rails.env}"
]

inject_into_file 'config/application.rb', generator, :after => '[:password]'
