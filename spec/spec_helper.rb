begin
  # make sure that this file is not loaded twice
  @_neo4j_rspec_loaded = true

  #require "bundler/setup"
  require 'rspec'
  require 'rspec-apigen'
  require 'fileutils'
  require 'tmpdir'


  $LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "lib")

  require 'neo4j'


# load all fixture classes
  fixture_path = File.join(File.dirname(__FILE__), 'fixture')
  Dir.entries(fixture_path).find_all { |f| f =~ /\.rb$/ }.each do |file|
    require File.join(fixture_path, file)
  end

#Neo4j::Config[:storage_path] = File.join(Dir::tmpdir, 'neo4j-rspec')


  RSpec.configure do |c|
#  c.filter = { :type => :integration}
    c.before(:all, :type => :integration) do
      # looks like there is a bug in rspec - this will prevent before all being called twice (sometimes)
#    unless @before_all
      FileUtils.rm_rf Neo4j::Config[:storage_path]
      FileUtils.mkdir_p(Neo4j::Config[:storage_path])
#    end
      @before_all = true
    end

    c.after(:all, :type => :integration) do
      @before_all = false

      Neo4j.shutdown
      FileUtils.rm_rf Neo4j::Config[:storage_path]
    end

    c.before(:each, :type => :integration) do
      unless @before_each
        Neo4j::Transaction.new
      end
      @before_each = true
    end

    c.after(:each, :type => :integration) do
      @before_each = false
      Neo4j::Transaction.finish
    end
  end

end unless @_neo4j_rspec_loaded


# http://blog.davidchelimsky.net/2010/07/01/rspec-2-documentation/
# http://asciicasts.com/episodes/157-rspec-matchers-macros
#http://kpumuk.info/ruby-on-rails/my-top-7-rspec-best-practices/
# http://eggsonbread.com/2010/03/28/my-rspec-best-practices-and-tips/
# http://www.slideshare.net/gsterndale/straight-up-rspec
#org.neo4j.kernel.impl.core.NodeProxy.class_eval do
#end


