begin
  # make sure that this file is not loaded twice
  @_neo4j_rspec_loaded = true

  #require "bundler/setup"
  require 'rspec'
  require 'rspec-apigen'
  require 'fileutils'
  require 'tmpdir'
  require 'rspec-rails-matchers'

  $LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "lib")

  require 'neo4j'

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

  # load all fixture classes
  fixture_path = File.join(File.dirname(__FILE__), 'fixture')
  Dir.entries(fixture_path).find_all { |f| f =~ /\.rb$/ }.each do |file|
    require File.join(fixture_path, file)
  end

  # set database storage location
  Neo4j::Config[:storage_path] = File.join(Dir.tmpdir, 'neo4j-rspec-tests')

  rm_db_storage

  RSpec.configure do |c|

#  c.filter = { :type => :transactional}
    c.before(:each, :type => :transactional) do
      new_tx
    end

    c.after(:each, :type => :transactional) do
      finish_tx
    end
  end


  module TempModel
    @@_counter = 1
    def self.set(klass)
      name = "Model_#{@@_counter}"
      @@_counter += 1
      const_set(name,klass)
      klass
    end
  end

  def model_subclass(&block)
    TempModel.set(Class.new(Neo4j::Model, &block))
  end
end unless @_neo4j_rspec_loaded

