# To run coverage via travis
require 'simplecov'
require 'dotenv'
require 'timecop'

Dotenv.load

SimpleCov.start
if ENV['CI'] == 'true'
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

# To run it manually via Rake
if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
  SimpleCov.start
end

require 'bundler/setup'
require 'rspec'
require 'its'
require 'fileutils'
require 'tmpdir'
require 'logger'
require 'active_attr/rspec'

require 'neo4j-core'
require 'neo4j-server'
require 'neo4j-embedded' if RUBY_PLATFORM == 'java'
require 'neo4j'
require 'unique_class'

require 'pry' if ENV['APP_ENV'] == 'debug'

require 'neo4j/core/cypher_session'
require 'neo4j/core/cypher_session/adaptors/http'
require 'neo4j/core/cypher_session/adaptors/embedded'

class MockLogger
  def debug(*_args)
  end
end

module Rails
  def self.logger
    MockLogger.new
  end

  def self.root
    # Placeholder
    Pathname.new(Dir.pwd)
  end
end


Dir["#{File.dirname(__FILE__)}/shared_examples/**/*.rb"].each { |f| require f }

EMBEDDED_DB_PATH = File.join(Dir.tmpdir, 'neo4j-core-java')

I18n.enforce_available_locales = false

module Neo4jSpecHelpers
  extend ActiveSupport::Concern

  def server_username
    ENV['NEO4J_USERNAME'] || 'neo4j'
  end

  def server_password
    ENV['NEO4J_PASSWORD'] || 'neo4jrb rules, ok?'
  end

  def basic_auth_hash
    {
      username: server_username,
      password: server_password
    }
  end

  def server_url
    ENV['NEO4J_URL'] || 'http://localhost:7474'
  end

  def session_mode
    RUBY_PLATFORM == 'java' ? :embedded : :http
  end

  def create_session(options = {})
    @current_session = Neo4j::Core::CypherSession.new(session_adaptor(options.merge(wrap_level: :proc)))
    Neo4j::ActiveBase.set_current_session(@current_session)
  end

  def new_query
    Neo4j::Core::Query.new
  end

  def session_adaptor(options = {})
    case session_mode
    when :embedded
      Neo4j::Core::CypherSession::Adaptors::Embedded.new(EMBEDDED_DB_PATH, {impermanent: true, auto_commit: true}.merge(options))
    when :http
      Neo4j::Core::CypherSession::Adaptors::HTTP.new(server_url, {basic_auth: basic_auth_hash}.merge(options))
    else
      fail "Invalid session_mode: #{session_mode.inspect}"
    end
  end

  def session
    @current_session
  end

  def current_session
    @current_session
  end

  def log_queries!
    Neo4j::Core::CypherSession::Adaptors::Base.subscribe_to_query(&method(:puts))
    Neo4j::Core::CypherSession::Adaptors::HTTP.subscribe_to_request(&method(:puts))
    Neo4j::Core::CypherSession::Adaptors::Embedded.subscribe_to_transaction(&method(:puts))
  end

  class_methods do
    def let_config(var_name)
      before do
        @neo4j_config_vars ||= ActiveSupport::HashWithIndifferentAccess.new
        @neo4j_config_vars[var_name] = Neo4j::Config[var_name]
        Neo4j::Config[var_name]      = yield
      end

      after do
        Neo4j::Config[var_name] = @neo4j_config_vars[var_name]
        @neo4j_config_vars.delete(var_name)
      end
    end
  end

  # rubocop:disable Style/GlobalVars
  def expect_queries(count)
    start_count = $expect_queries_count
    yield
    expect($expect_queries_count - start_count).to eq(count)
  end
end

$expect_queries_count = 0
Neo4j::Core::CypherSession::Adaptors::Base.subscribe_to_query do |_message|
  $expect_queries_count += 1
end
# rubocop:enable Style/GlobalVars

FileUtils.rm_rf(EMBEDDED_DB_PATH)

Dir["#{File.dirname(__FILE__)}/shared_examples/**/*.rb"].each { |f| require f }

def clear_model_memory_caches
  Neo4j::ActiveNode::Labels.clear_wrapped_models
end

def delete_db(session = current_session)
  # clear_model_memory_caches
  session.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
end

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

module ActiveNodeRelStubHelpers
  def stub_active_node_class(class_name, &block)
    stub_const class_name, active_node_class(class_name, &block)
  end

  def stub_active_rel_class(class_name, &block)
    stub_const class_name, active_rel_class(class_name, &block)
  end

  def stub_named_class(class_name, superclass = nil, &block)
    stub_const class_name, named_class(class_name, superclass, &block)
  end

  def active_node_class(class_name, &block)
    named_class(class_name) do
      include Neo4j::ActiveNode

      module_eval(&block) if block
    end
  end

  def active_rel_class(class_name, &block)
    named_class(class_name) do
      include Neo4j::ActiveRel

      module_eval(&block) if block
    end
  end

  def named_class(class_name, superclass = nil, &block)
    Class.new(superclass || Object) do
      @class_name = class_name
      class << self
        attr_reader :class_name
        alias_method :name, :class_name
        def to_s
          name
        end
      end

      module_eval(&block) if block
    end
  end
end

def before_session
  @current_session.close if @current_session
  yield
  create_session
end

def current_transaction
  Neo4j::Transaction.current_for(@current_session)
end

RSpec.configure do |c|
  c.include Neo4jSpecHelpers

  c.before(:all) do
    @current_session.close if @current_session
    create_session
  end

  c.before(:each) do
    # TODO: What to do about this?
    Neo4j::Session._listeners.clear
    @current_session || create_session
  end

  c.after(:each) do
    if current_transaction
      puts 'WARNING forgot to close transaction'
      current_transaction.close
    end
  end

  c.exclusion_filter = {
    api: lambda do |ed|
      RUBY_PLATFORM == 'java' && ed == :server
    end
  }

  c.include ActiveNodeRelStubHelpers
end
