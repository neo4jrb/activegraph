# Usage: rails new myapp -m neo4j.rb -O

gem "neo4j", '~> 9.0.0'


generator = %q[
    config.generators do |g|
      g.orm             :neo4j
    end

    # Configure where to connect to the Neo4j DB
    # Note that embedded db is only available for JRuby
    # config.neo4j.session.type = :http
    # config.neo4j.session.url = 'http://localhost:7474'
    #  or
    # config.neo4j.session.type = :bolt
    # config.neo4j.session.url = 'bolt://localhost:7687'
    #  or
    # config.neo4j.session.type = :embedded
    # config.neo4j.session.path = Rails.root.join('neo4j-db').to_s

]

application generator

inject_into_file 'config/application.rb', "\nrequire 'neo4j/railtie'", after: 'require "active_record/railtie"'

inject_into_file 'config/application.rb', "\nrequire 'neo4j/railtie'", after: "require 'rails/all'"

yaml_data = <<YAML
development:
  type: http
  url: http://localhost:7474
test:
  type: http
  url: http://localhost:7575
YAML

create_file 'config/neo4j.yml', yaml_data
