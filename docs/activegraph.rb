# Usage: rails new myapp -m activegraph.rb

gem 'activegraph', path: '~/mck/activegraph'
gem 'neo4j-ruby-driver'

gem_group :development do
  gem 'neo4j-rake_tasks'
end

inject_into_file 'config/application.rb', before: '# Require the gems listed in Gemfile' do <<END
require 'active_graph/railtie'
require 'neo4j_ruby_driver'

END
end

gsub_file 'config/application.rb', "require 'rails'", ''

generator = %q[
    # Enable ActiveGraph generators, e.g:  rails generate model Admin --parent User
    config.generators do |g|
      g.orm :active_graph
      # g.test_framework  :rspec, :fixture => false
    end

]

environment generator
environment nil, env: 'development' do <<END
config.neo4j.driver.url = 'neo4j://localhost:7472'
config.neo4j.driver.auth_token = Neo4j::Driver::AuthTokens.basic('neo4j', 'password')
config.neo4j.driver.encryption = false
END
end
