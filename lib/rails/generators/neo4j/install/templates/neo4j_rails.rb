# Enable Neo4j generators, e.g:  rails generate model Admin --parent User
config.generators do |g|
  g.orm             :neo4j
  g.test_framework  :rspec, :fixture => false
end

# Configure where the neo4j database should exist
config.neo4j.storage_path = "#{config.root}/db/neo4j-#{Rails.env}"