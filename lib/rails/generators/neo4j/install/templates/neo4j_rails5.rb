# Configure NEO4J as the ORM
Rails.application.config.generators do |g|
  g.orm             :neo4j
end

# Configure where the neo4j database should exist
Neo4j::Config.use do |config|
  config[:storage_path] = "#{Rails.application.config.root}/db/neo4j-#{Rails.env}"
end
