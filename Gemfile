source 'http://rubygems.org'

gemspec

#gem 'neo4j-java-driver', path: '/Users/amitsuryavanshi/projects/Amit-Git/neo4j-ruby-driver'

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
