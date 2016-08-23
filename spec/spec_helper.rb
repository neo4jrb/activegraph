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

require 'neo4j-core'
require 'neo4j-server'
require 'neo4j-embedded' if RUBY_PLATFORM == 'java'
require 'neo4j'
require 'unique_class'

require 'pry' if ENV['APP_ENV'] == 'debug'


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

  def create_embedded_session
    require 'neo4j-embedded/embedded_impermanent_session'
    session = Neo4j::Session.open(:impermanent_db, EMBEDDED_DB_PATH, auto_commit: true)
    session.start
  end

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

  def create_server_session(options = {})
    Neo4j::Session.open(:server_db, server_url, {basic_auth: basic_auth_hash}.merge(options))
    delete_db # Should separate this out
  end

  def create_session
    if RUBY_PLATFORM == 'java'
      create_embedded_session
    else
      create_server_session
    end
  rescue Faraday::ConnectionFailed
    puts 'Could not create Neo4j session'
    exit!
  end

  def create_named_server_session(name, default = nil)
    Neo4j::Session.open_named(:server_db, name, default, server_url, basic_auth: basic_auth_hash)
  end

  def session
    Neo4j::Session.current
  end

  def log_queries!
    Neo4j::Server::CypherSession.log_with do |message|
      puts message
    end
  end

  def action_controller_params(args)
    ActionController::Parameters.new(args)
  end

  def handle_child_output(read, write)
    read.close
    begin
      rest = yield
      write.puts [Marshal.dump(rest)].pack('m')
    rescue StandardError => e
      write.puts [Marshal.dump(e)].pack('m')
    end
    exit!
  end

  def do_in_child(&block)
    read, write = IO.pipe
    pid = fork do
      handle_child_output(read, write, &block)
    end
    write.close
    result = Marshal.load(read.read.unpack('m').first)
    Process.wait2(pid)

    fail result if result.class < Exception
    result
  end

  # A trick to load action_controller without requiring in all specs. Not working in JRuby.
  def using_action_controller
    if RUBY_PLATFORM == 'java'
      require 'action_controller'
      yield
    else
      do_in_child do
        require 'action_controller'
        yield
      end
    end
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
Neo4j::Server::CypherSession.log_with do |_message|
  $expect_queries_count += 1
end
# rubocop:enable Style/GlobalVars

FileUtils.rm_rf(EMBEDDED_DB_PATH)

Dir["#{File.dirname(__FILE__)}/shared_examples/**/*.rb"].each { |f| require f }

def clear_model_memory_caches
  Neo4j::ActiveNode::Labels::WRAPPED_CLASSES.clear
  Neo4j::ActiveNode::Labels.clear_wrapped_models
end

def delete_db
  # clear_model_memory_caches
  Neo4j::Session.current._query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
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

# Introduces `let_context` helper method
# This allows us to simplify the case where we want to
# have a context which contains one or more `let` statements
module RSpecHelpers
  # Supports giving either a Hash or a String and a Hash as arguments
  # In both cases the Hash will be used to define `let` statements
  # When a String is specified that becomes the context description
  # If String isn't specified, Hash#inspect becomes the context description
  def let_context(*args, &block)
    context_string, hash =
      case args.map(&:class)
      when [String, Hash] then ["#{args[0]} #{args[1]}", args[1]]
      when [Hash] then [args[0].inspect, args[0]]
      end

    context(context_string) do
      hash.each { |var, value| let(var) { value } }

      instance_eval(&block)
    end
  end
end

def before_session
  Neo4j::Session.current.close if Neo4j::Session.current
  yield
  create_session
end

RSpec.configure do |c|
  c.extend RSpecHelpers
  c.include Neo4jSpecHelpers

  c.before(:all) do
    Neo4j::Session.current.close if Neo4j::Session.current
    create_session
  end

  c.before(:each) do
    Neo4j::Session._listeners.clear
    curr_session = Neo4j::Session.current
    curr_session || create_session
  end

  c.after(:each) do
    if Neo4j::Transaction.current
      puts 'WARNING forgot to close transaction'
      Neo4j::Transaction.current.close
    end
  end

  c.exclusion_filter = {
    api: lambda do |ed|
      RUBY_PLATFORM == 'java' && ed == :server
    end
  }

  c.include ActiveNodeRelStubHelpers
end
