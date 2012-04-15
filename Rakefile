srand # Workaround for JRuby bug 1.6.5
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

require 'rake'
require 'rspec/core/rake_task'
require "bundler/gem_tasks"
require 'rdoc/task'

require "neo4j/version"


desc "Run all specs"
RSpec::Core::RakeTask.new("spec") do |t|
  t.rspec_opts = ["-c"]
  t.pattern = 'spec/**/*_spec.rb'
end

require 'rake/testtask'
Rake::TestTask.new(:test_generators) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

task :default => 'spec'

