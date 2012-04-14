require 'rubygems'
require "bundler/setup"
require 'rspec'
require 'fileutils'
require 'tmpdir'
require 'active_model' # Need to pull this before shoulda-matcher, so it can configure RSpec
require 'shoulda-matchers'
require 'its'
require 'benchmark'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'neo4j'
require 'logger'

def rm_db_storage
  FileUtils.rm_rf Neo4j::Config[:storage_path]
  raise "Can't delete db" if File.exist?(Neo4j::Config[:storage_path])
end

def finish_tx
  return unless @tx
  @tx.success
  @tx.finish
  @tx = nil
end

def new_tx
  finish_tx if @tx
  @tx = Neo4j::Transaction.new
end

# ensure the translations get picked up for tests
I18n.load_path += Dir[File.join(File.dirname(__FILE__), '..', 'config', 'locales', '*.{rb,yml}')]

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# load all fixture classes
Dir["#{File.dirname(__FILE__)}/fixture/**/*.rb"].each { |f| require f }

Neo4j::Config[:storage_path] = File.join(Dir.tmpdir, "neo4j_rspec")
FileUtils.rm_rf Neo4j::Config[:storage_path]

RSpec.configure do |c|
  $name_counter = 0

  c.filter_run_excluding :identity_map => true if not Neo4j::IdentityMap.enabled
  c.filter_run_excluding :slow => ENV['TRAVIS'] != 'true'

  c.extend(UnitTest, :type => :unit)

  c.before(:suite) do
    Neo4j::Config[:logger_level] = Logger::ERROR
    Neo4j::Config[:debug_java] = true
    Neo4j::Config[:storage_path] = File.join(Dir.tmpdir, "neo4j_rspec")
    Neo4j::Config[:identity_map] = (ENV['IDENTITY_MAP'] == "true") # faster tests
    Neo4j::IdentityMap.enabled = (ENV['IDENTITY_MAP'] == "true") # this is normally set in the rails rack middleware

    FileUtils.rm_rf Neo4j::Config[:storage_path]
    Dir.mkdir(Neo4j::Config[:storage_path])
  end

  c.after(:suite) do
    Neo4j.shutdown if Neo4j.running?
    FileUtils.rm_rf Neo4j::Config[:storage_path]
  end

  c.after(:each, :type => :integration) do
    Neo4j::Rails::Model.close_lucene_connections
    Neo4j::Transaction.run do
      Neo4j.threadlocal_ref_node = Neo4j::Node.new :name => "ref_#{$name_counter}"
      $name_counter += 1
    end
  end

end


module TempModel
  @@_counter = 1

  def self.set(klass, name=nil)
    name ||= "Model_#{@@_counter}"
    @@_counter += 1
    klass.class_eval <<-RUBY
	def self.to_s
	  "#{name}"
	end
    RUBY
    Kernel.const_set(name, klass)
    klass
  end
end

def create_model(base_class = Neo4j::Rails::Model, name=nil, &block)
  klass = Class.new(base_class) do
    def mock_save(java_entity)
      @_java_node = java_entity
      @@instances ||= {}
      @@instances[java_entity.neo_id] = self
      self
      k = self.class
      def k.load_entity(neo_id)
        @@instances[neo_id]
      end
      self
    end
  end
  TempModel.set(klass, name)
  base_class.inherited(klass)
  klass.class_eval &block if block
  klass
end

def create_rel_model(base_class = Neo4j::Rails::Relationship, &block)
  @@_rel_counter ||= 1
  name ||= "Relationship_#{@@_rel_counter}"
  @@_rel_counter += 1
  klass = Class.new(base_class)
  TempModel.set(klass, name)
  base_class.inherited(klass)
  klass.class_eval &block if block
  klass
end

def create_node_mixin(name=nil, &block)
  klass = Class.new
  TempModel.set(klass, name)
  klass.send(:include, Neo4j::NodeMixin)
  klass.class_eval &block if block
  klass
end


