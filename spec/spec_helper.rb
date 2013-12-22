require 'rubygems'
require "bundler/setup"
require 'rspec'
require 'fileutils'
require 'tmpdir'
require 'logger'

require 'neo4j-core'
require 'neo4j'


Dir["#{File.dirname(__FILE__)}/shared_examples/**/*.rb"].each { |f| require f }

EMBEDDED_DB_PATH = File.join(Dir.tmpdir, "neo4j-core-java")

def create_session
  if RUBY_PLATFORM != 'java'
    create_server_session
  else
    require "neo4j-embedded/embedded_impermanent_session"
    create_embedded_session
  end
end

def create_embedded_session
  session = Neo4j::Session.open(:impermanent_db, EMBEDDED_DB_PATH, auto_commit: true)
  session.start
end

def create_server_session
  Neo4j::Session.open(:server_db, "http://localhost:7474")
end

FileUtils.rm_rf(EMBEDDED_DB_PATH)

RSpec.configure do |c|

  c.before(:all) do
    Neo4j::Session.current.close if Neo4j::Session.current
    create_session
  end

  c.before(:each) do
    curr_session = Neo4j::Session.current
    curr_session || create_session
  end


end

