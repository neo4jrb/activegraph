require 'active_graph'
require 'find'

server_url = ENV['NEO4J_URL'] || 'bolt://localhost:7687'
ActiveGraph::Base.driver = Neo4j::Driver::GraphDatabase.driver(server_url, Neo4j::Driver::AuthTokens.basic('neo4j', 'password'))

def load_migration(suffix)
  Find.find('myapp/db/neo4j/migrate') do |path|
    load path if path =~ /.*#{suffix}$/
  end
end
