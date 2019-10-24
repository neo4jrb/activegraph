source 'http://rubygems.org'

gemspec

# gem 'neo4j-core', github: 'neo4jrb/neo4j-core', branch: 'master' if ENV['CI']

branch = ENV['NEO4J_CORE_BRANCH'] || ENV['TRAVIS_PULL_REQUEST_BRANCH'] || ENV['TRAVIS_BRANCH']
slug = !ENV['TRAVIS_PULL_REQUEST_SLUG'].to_s.empty? ? ENV['TRAVIS_PULL_REQUEST_SLUG'] : ENV['TRAVIS_REPO_SLUG']

# gem 'neo4j-ruby-driver', path: '../neo4j-ruby-driver'

gem 'listen', '< 3.1'

active_model_version = ENV['ACTIVE_MODEL_VERSION']
gem 'activemodel', "~> #{active_model_version}" if active_model_version

group 'test' do
  gem 'coveralls', require: false
  gem 'overcommit'
  gem 'codecov', require: false
  gem 'simplecov', require: false
  gem 'simplecov-html', require: false
  gem 'rspec', '~> 3.4'
  gem 'its'
  gem 'test-unit'
  gem 'colored'
  gem 'dotenv'
  gem 'timecop'
end
