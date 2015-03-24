require 'rake'
require 'bundler/gem_tasks'
require 'neo4j-core'
load 'neo4j/tasks/neo4j_server.rake'
load 'neo4j/tasks/migration.rake'

desc 'Generate YARD documentation'

namespace :docs do
  task :yard do
    `rm -rf docs/_build/_yard/*`
    abort("can't generate YARD") unless system('yard -p docs/_yard/custom_templates -f rst')
  end

  task :sphinx do
    `rm -rf docs/api/*`
    `cp -r docs/_build/_yard/* docs/api/`
    abort("can't generate Sphinx docs") unless system('cd docs && make html')
  end

  task :open do
    `open docs/_build/html/index.html`
  end

  task all: [:yard, :sphinx]
end

task docs: 'docs:all'

desc 'Run neo4j.rb specs'
task 'spec' do
  success = system('rspec spec')
  abort('RSpec neo4j failed') unless success
end

require 'rake/testtask'
Rake::TestTask.new(:test_generators) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

desc 'Generate coverage report'
task 'coverage' do
  ENV['COVERAGE'] = 'true'
  rm_rf 'coverage/'
  task = Rake::Task['spec']
  task.reenable
  task.invoke
end

task default: ['spec']
