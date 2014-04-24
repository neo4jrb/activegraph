require 'rake'
require "bundler/gem_tasks"
require 'neo4j/tasks/neo4j_server'

desc "Generate YARD documentation"
task 'yard' do
  abort("can't generate YARD") unless system('yardoc - README.md')
end

desc "Run neo4j-core specs"
task 'spec' do
  success = system('rspec spec')
  abort("RSpec neo4j failed") unless success
end

require 'rake/testtask'
Rake::TestTask.new(:test_generators) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

task :rm_server_db do
  FileUtils.rm_rf('./neo4j/data')
  FileUtils.mkdir_p('./neo4j/data')
end

desc 'stop, clean db, start'
task :clean_db => ['neo4j:stop', 'rm_server_db', 'neo4j:start']

task :default => ['spec']

