# To run coverage via travis
require 'simplecov'
require 'dotenv'
require 'timecop'

Dotenv.load

SimpleCov.start do
  add_filter 'spec'
end
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

require 'active_graph/core'
require 'active_graph'
require 'unique_class'

require 'pry' if ENV['APP_ENV'] == 'debug'

require 'dryspec/helpers'
require 'neo4j_spec_helpers'
require 'action_controller'

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

I18n.enforce_available_locales = false

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

Dir["#{File.dirname(__FILE__)}/shared_examples/**/*.rb"].each { |f| require f }

def clear_model_memory_caches
  ActiveGraph::Relationship::Types::WRAPPED_CLASSES.clear
  ActiveGraph::Node::Labels::WRAPPED_CLASSES.clear
  ActiveGraph::Node::Labels.clear_wrapped_models
end

def delete_db(executor = ActiveGraph::Base)
  executor.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
end

def delete_schema
  ActiveGraph::Core::Label.drop_constraints
  ActiveGraph::Core::Label.drop_indexes
end

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

module ActiveNodeRelStubHelpers
  def stub_node_class(class_name, with_constraint = true, &block)
    stub_const class_name, node_class(class_name, with_constraint, &block)
  end

  def stub_relationship_class(class_name, &block)
    stub_const class_name, relationship_class(class_name, &block)
  end

  def stub_named_class(class_name, superclass = nil, &block)
    stub_const class_name, named_class(class_name, superclass, &block)
    ActiveGraph::ModelSchema.reload_models_data!
  end

  def node_class(class_name, with_constraint = true, &block)
    named_class(class_name) do
      include ActiveGraph::Node

      module_eval(&block) if block
    end.tap { |model| create_id_property_constraint(model, with_constraint) }
  end

  def create_id_property_constraint(model, with_constraint)
    unless model.id_property_info[:type][:constraint] == false || !with_constraint || model.id_property_name == :neo_id
      create_constraint(model.mapped_label_name, model.id_property_name, type: :unique)
    end
  end

  def relationship_class(class_name, &block)
    named_class(class_name) do
      include ActiveGraph::Relationship

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
    ActiveGraph::Base.label_object(label_name).create_constraint(property, options)
    ActiveGraph::ModelSchema.reload_models_data!
  end

  def create_index(label_name, property, options = {})
    ActiveGraph::Base.label_object(label_name).create_index(property, **options)
    ActiveGraph::ModelSchema.reload_models_data!
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
end

ActiveGraph::Config[:logger_level] = Logger::DEBUG if ENV['DEBUG']

def set_default_driver
  server_url = ENV['NEO4J_URL'] || 'bolt://localhost:7687'
  ActiveGraph::Base.driver =
    Neo4j::Driver::GraphDatabase.driver(server_url, Neo4j::Driver::AuthTokens.basic('neo4j', 'pass'))
end

set_default_driver

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.configure do |config|
  config.extend FixingRSpecHelpers
  config.include Neo4jSpecHelpers
  config.include ActiveNodeRelStubHelpers
  config.include Neo4jEntityFindingHelpers
  config.extend DRYSpec::Helpers

  # Setup the current driver
  config.before(:suite) do
  end

  config.after(:suite) do
    # Ability to close driver?
  end

  config.before(:each) do
    ActiveGraph::ModelSchema::MODEL_INDEXES.clear
    ActiveGraph::ModelSchema::MODEL_CONSTRAINTS.clear
    ActiveGraph::ModelSchema::REQUIRED_INDEXES.clear
    ActiveGraph::Node.loaded_classes.clear
    ActiveGraph::ModelSchema.reload_models_data!
  end

  config.before(:all) do
    ActiveGraph::Config[:id_property] = ENV['NEO4J_ID_PROPERTY'].try :to_sym
  end

  config.before(:each) do
    delete_db
    delete_schema
    @base_logger = spy('Base logger')
    allow(ActiveGraph::Base).to receive(:logger).and_return(@base_logger)
  end

  # TODO marshalling java objects, is it necessary?
  config.filter_run_excluding :ffi_only if RUBY_PLATFORM =~ /java/
end
