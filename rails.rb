# Usage: rails new myapp -m neo4j.rb

NEO4J_VERSION = "2.0.0.alpha.7"

gsub_file 'Gemfile', /gem 'sql.*/, "gem 'neo4j', '#{NEO4J_VERSION}'"
gsub_file 'Gemfile', /gem 'activerecord.*/, "gem 'neo4j', '#{NEO4J_VERSION}'"
 
dev_gems = <<END


group :development do
  gem 'rspec-rails'
end

END
inject_into_file 'Gemfile', dev_gems, :after => "#{NEO4J_VERSION}'"

gsub_file 'config/application.rb', "require 'rails/all'", <<END
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'active_resource/railtie'
require 'rails/test_unit/railtie'
require 'neo4j'
END


gsub_file "config/application.rb", "config.active_record.whitelist_attributes = true", "# config.active_record.whitelist_attributes = true"

gsub_file "config/environments/development.rb", "config.active_record.mass_assignment_sanitizer = :strict", "# config.active_record.mass_assignment_sanitizer = :strict"
gsub_file "config/environments/development.rb", "config.active_record.auto_explain_threshold_in_seconds = 0.5", "# config.active_record.auto_explain_threshold_in_seconds = 0.5"

# we are using JRuby - use Threads !
gsub_file "config/environments/production.rb", "# config.threadsafe!", "config.threadsafe!"

remove_file "config/database.yml"

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
