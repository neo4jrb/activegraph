source 'http://rubygems.org'

gemspec

gem 'neo4j-core', github: 'neo4jrb/neo4j-core', branch: 'master'
# gem 'neo4j-core', git: 'https://github.com/neo4jrb/neo4j-core'
# gem 'orm_adapter', :path => '../orm_adapter'

gem 'coveralls', require: false

group 'development' do
  gem 'pry'
  gem 'os' # for neo4j-server rake task
  gem 'rake'
  gem 'yard'

  gem 'guard'
  gem 'guard-rubocop'
  gem 'guard-rspec'
end

group 'test' do
  gem 'simplecov', require: false
  gem 'simplecov-html', require: false
  gem 'rspec', '~> 2.0'
  gem 'its'
  gem 'test-unit'
end
