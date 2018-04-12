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

require 'neo4j/core/cypher_session'
require 'neo4j/core/cypher_session/adaptors/http'
require 'neo4j/core/cypher_session/adaptors/bolt'
require 'neo4j/core/cypher_session/adaptors/embedded'

class MockLogger
  def debug(*_args)
  end

  def debug?
    false
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

  def new_query
    Neo4j::ActiveBase.new_query
  end

  def current_session
    Neo4j::ActiveBase.current_session
  end

  def session
    current_session
  end

  def neo4j_query(*args)
    current_session.query(*args)
  end

  def log_queries!
    Neo4j::Core::CypherSession::Adaptors::Base.subscribe_to_query(&method(:puts))
    Neo4j::Core::CypherSession::Adaptors::HTTP.subscribe_to_request(&method(:puts))
    Neo4j::Core::CypherSession::Adaptors::Embedded.subscribe_to_transaction(&method(:puts))
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
    def let_config(var_name, value)
      around do |example|
        old_value = Neo4j::Config[var_name]
        Neo4j::Config[var_name] = value
        example.run
        Neo4j::Config[var_name] = old_value
      end
    end

    def capture_output!(variable)
      around do |example|
        @captured_stream = StringIO.new

        original_stream = $stdout
        $stdout = @captured_stream

        example.run

        $stdout = original_stream
      end
      let(variable) { @captured_stream.string }
    end

    def let_env_variable(var_name)
      around do |example|
        old_value = ENV[var_name.to_s]
        ENV[var_name.to_s] = yield
        example.run
        ENV[var_name.to_s] = old_value
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

module Neo4jEntityFindingHelpers
  def rel_cypher_string(dir = :both, type = nil)
    type_string = type ? ":#{type}" : ''
    case dir
    when :both then "-[r#{type_string}]-"
    when :incoming then "<-[r#{type_string}]-"
    when :outgoing then "-[r#{type_string}]->"
    end
  end

  def first_rel_type(node, dir = :both, type = nil)
    node.query_as(:n).match("(n)#{rel_cypher_string(dir, type)}()").pluck('type(r)').first
  end

  def node_rels(node, dir = :both, type = nil)
    node.query_as(:n).match("(n)#{rel_cypher_string(dir, type)}()").pluck('r')
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
  Neo4j::ActiveRel::Types::WRAPPED_CLASSES.clear
  Neo4j::ActiveNode::Labels::WRAPPED_CLASSES.clear
  Neo4j::ActiveNode::Labels.clear_wrapped_models
end

def delete_db
  Neo4j::ActiveBase.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
end

def delete_schema
  Neo4j::Core::Label.drop_uniqueness_constraints_for(Neo4j::ActiveBase.current_session)
  Neo4j::Core::Label.drop_indexes_for(Neo4j::ActiveBase.current_session)
end

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

module ActiveNodeRelStubHelpers
  def stub_active_node_class(class_name, with_constraint = true, &block)
    stub_const class_name, active_node_class(class_name, with_constraint, &block)
  end

  def stub_active_rel_class(class_name, &block)
    stub_const class_name, active_rel_class(class_name, &block)
  end

  def stub_named_class(class_name, superclass = nil, &block)
    stub_const class_name, named_class(class_name, superclass, &block)
    Neo4j::ModelSchema.reload_models_data!
  end

  def active_node_class(class_name, with_constraint = true, &block)
    named_class(class_name) do
      include Neo4j::ActiveNode

      module_eval(&block) if block
    end.tap { |model| create_id_property_constraint(model, with_constraint) }
  end

  def create_id_property_constraint(model, with_constraint)
    # return if model.id_property_info[:type][:constraint] == false || !with_constraint

    puts 'model.mapped_label_name', model.mapped_label_name.inspect
    puts 'model.id_property_name', model.id_property_name
    create_constraint(model.mapped_label_name, model.id_property_name, type: :unique)
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

  def id_property_value(o)
    o.send o.class.id_property_name
  end

  def create_constraint(label_name, property, options = {})
    Neo4j::ActiveBase.label_object(label_name).create_constraint(property, options)
    Neo4j::ModelSchema.reload_models_data!
  end

  def create_index(label_name, property, options = {})
    Neo4j::ActiveBase.label_object(label_name).create_index(property, options)
    Neo4j::ModelSchema.reload_models_data!
  end
end

# Should allow for http on java
TEST_SESSION_MODE = RUBY_PLATFORM == 'java' ? :embedded : :http

session_adaptor = case TEST_SESSION_MODE
                  when :embedded
                    Neo4j::Core::CypherSession::Adaptors::Embedded.new(EMBEDDED_DB_PATH, impermanent: true, auto_commit: true, wrap_level: :proc)
                  when :http
                    server_url = ENV['NEO4J_URL'] || 'http://localhost:7474'
                    server_username = ENV['NEO4J_USERNAME'] || 'neo4j'
                    server_password = ENV['NEO4J_PASSWORD'] || 'neo4jrb rules, ok?'

                    basic_auth_hash = {username: server_username, password: server_password}

                    case URI(server_url).scheme
                    when 'http'
                      Neo4j::Core::CypherSession::Adaptors::HTTP.new(server_url, basic_auth: basic_auth_hash, wrap_level: :proc)
                    when 'bolt'
                      Neo4j::Core::CypherSession::Adaptors::Bolt.new(server_url, wrap_level: :proc) # , logger_level: Logger::DEBUG)
                    else
                      fail "Invalid scheme for NEO4J_URL: #{scheme} (expected `http` or `bolt`)"
                    end
                  end

module FixingRSpecHelpers
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

  def subject_should_raise(error, message = nil)
    it_string = error.to_s
    it_string += " (#{message.inspect})" if message

    it it_string do
      expect { subject }.to raise_error error, message
    end
  end
end

Neo4j::ActiveBase.current_adaptor = session_adaptor

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.configure do |config|
  config.extend FixingRSpecHelpers
  config.include Neo4jSpecHelpers
  config.include ActiveNodeRelStubHelpers
  config.include Neo4jEntityFindingHelpers

  # Setup the current session
  config.before(:suite) do
  end

  config.after(:suite) do
    # Ability to close session?
  end

  config.before(:each) do
    Neo4j::ModelSchema::MODEL_INDEXES.clear
    Neo4j::ModelSchema::MODEL_CONSTRAINTS.clear
    Neo4j::ModelSchema::REQUIRED_INDEXES.clear
    Neo4j::ActiveNode.loaded_classes.clear
    Neo4j::ModelSchema.reload_models_data!
  end

  config.before(:all) do
    Neo4j::Config[:id_property] = ENV['NEO4J_ID_PROPERTY'].try :to_sym
  end


  config.before(:each) do
    @active_base_logger = spy('ActiveBase logger')
    allow(Neo4j::ActiveBase).to receive(:logger).and_return(@active_base_logger)
  end

  # config.before(:each) do
  #   puts 'before each'
  #   # TODO: What to do about this?
  #   Neo4j::Session._listeners.clear
  #   @current_session || create_session
  # end

  # config.after(:each) do
  #   puts 'after each'
  #   if current_transaction
  #     puts 'WARNING forgot to close transaction'
  #     Neo4j::ActiveBase.wait_for_schema_changes
  #     current_transaction.close
  #   end
  # end

  config.exclusion_filter = {
    api: lambda do |ed|
      RUBY_PLATFORM == 'java' && ed == :server
    end
  }
end
