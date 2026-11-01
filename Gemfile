source 'http://rubygems.org'

gemspec

active_model_version = ENV['ACTIVE_MODEL_VERSION']
if active_model_version&.length&.positive?
  gem 'activemodel', "~> #{active_model_version}"
  # ActiveSupport < 8.1 passes the long-removed `quirks_mode` option to JSON.generate, which json >= 3
  # rejects (fixed upstream in Rails 8.1 and on 8-0-stable, unreleased as of 8.0.5.1). Apps on those
  # Rails versions must hold json below 3 themselves; mirror that for the matching CI rows.
  gem 'json', '< 3' if Gem::Version.new(active_model_version) < Gem::Version.new('8.1')
end

group 'test' do
  # gem 'coveralls', require: false
  gem 'overcommit'
  gem 'codecov', require: false
  gem 'simplecov', require: false
  gem 'simplecov-cobertura', require: false
  gem 'simplecov-html', require: false
  gem 'its'
  gem 'test-unit'
  gem 'colored'
  gem 'dotenv'
  gem 'timecop'
end
