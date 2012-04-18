source :gemcutter


# gem "neo4j-wrapper", :path => "/home/andreas/projects/neo4j-wrapper"

gemspec

group 'development' do
  gem 'guard'
  gem 'ruby_gntp', :require => false # GrowlNotify for Mac
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false
  gem "guard-rspec"
  #gem 'ruby-debug-base19' if RUBY_VERSION.include? "1.9"
  #gem 'ruby-debug-base' if RUBY_VERSION.include? "1.8"
  #gem "ruby-debug-ide"
end

group 'test' do
  gem "rake", ">= 0.8.7"
  gem "rdoc", ">= 2.5.10"
  gem "rspec", "~> 2.8"
  gem "its" # its(:with, :arguments) { should be_possible }
  gem 'shoulda-matchers', '~> 1.0'
  gem "test-unit"
end

