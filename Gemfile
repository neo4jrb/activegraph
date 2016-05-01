source 'http://rubygems.org'

gemspec

# gem 'neo4j-core', github: 'neo4jrb/neo4j-core', branch: 'master' if ENV['CI']
gem 'neo4j-core', github: 'neo4jrb/neo4j-core', branch: 'new_cypher_api' if ENV['CI']

# gem 'neo4j-core', path: '../neo4j-core'

# gem 'active_attr', github: 'neo4jrb/active_attr', branch: 'performance'
# gem 'active_attr', path: '../active_attr'

gem 'listen', '< 3.1'

group 'test' do
  gem 'coveralls', require: false
  gem 'codecov', require: false
  gem 'simplecov', require: false
  gem 'simplecov-html', require: false
  gem 'rspec', '~> 3.4'
  gem 'its'
  gem 'test-unit'
  gem 'overcommit'
  gem 'colored'
  gem 'dotenv'
  gem 'timecop'
end
