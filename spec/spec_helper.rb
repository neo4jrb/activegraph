require 'rubygems'
require "bundler/setup"
require 'rspec'
require 'fileutils'
require 'tmpdir'
#require 'its'
require 'logger'

#require 'neo4j-server'
#require 'neo4j-embedded'
require 'neo4j-core'
require 'neo4j-wrapper'
require 'neo4j'


Dir["#{File.dirname(__FILE__)}/shared_examples/**/*.rb"].each { |f| require f }

EMBEDDED_DB_PATH = File.join(Dir.tmpdir, "neo4j-core-java")

def create_embedded_session
  Neo4j::Session.open(:impermanent_db, EMBEDDED_DB_PATH, auto_commit: true)
  #Neo4j::Session.open(:embedded_db, EMBEDDED_DB_PATH)
end

def create_server_session
  Neo4j::Session.open(:server_db, "http://localhost:7474")
end

FileUtils.rm_rf(EMBEDDED_DB_PATH)

RSpec.configure do |c|

  c.before(:all, api: :server) do
    Neo4j::Session.current.close if Neo4j::Session.current
    create_server_session
  end

  c.before(:all, api: :embedded) do
    Neo4j::Session.current.close if Neo4j::Session.current
    create_embedded_session
    Neo4j::Session.current.start unless Neo4j::Session.current.running?
  end

  c.before(:each, api: :embedded) do
    curr_session = Neo4j::Session.current
    curr_session.close if curr_session && !curr_session.kind_of?(Neo4j::Embedded::EmbeddedSession)
    Neo4j::Session.current || create_embedded_session
    Neo4j::Session.current.start unless Neo4j::Session.current.running?
  end

  c.before(:each, api: :server) do
    curr_session = Neo4j::Session.current
    curr_session.close if curr_session && !curr_session.kind_of?(Neo4j::Server::CypherSession)
    Neo4j::Session.current || create_server_session
  end

  #c.after(:all, api: :server) do
  #  clean_server_db if Neo4j::Session.current && Neo4j::Session.current.kind_of?(Neo4j::Server::CypherSession)
  #end

  c.exclusion_filter = {
      :api => lambda do |ed|
        RUBY_PLATFORM != 'java' && ed == :embedded
      end
  }

end

