source :gemcutter

gemspec

group 'test' do
  gem "rake", ">= 0.8.7"
  gem "rdoc", ">= 2.5.10"
  gem "horo", ">= 1.0.2"
  gem "rspec", ">= 2.8"

  gem 'guard'
  gem 'ruby_gntp', :require => false # GrowlNotify for Mac
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false
  gem "guard-rspec"

  # use this version for rspec-rails-matchers which work with latest RSpec (Rspec => RSpec)
  gem "rspec-rails-matchers", :git => 'git://github.com/afcapel/rspec-rails-matchers.git'

  gem "test-unit"
  gem 'rcov'

  gem 'pry'

  gem 'neo4j-advanced',   :require => false
  gem 'neo4j-enterprise', :require => false
end

#gem 'ruby-debug-base19' if RUBY_VERSION.include? "1.9"
#gem 'ruby-debug-base' if RUBY_VERSION.include? "1.8"
#gem "ruby-debug-ide"
