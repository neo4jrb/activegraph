require 'rake'
require 'bundler/gem_tasks'
# load 'neo4j/tasks/migration.rake'

desc 'Generate YARD documentation'

require 'colored'

def system_or_fail(command)
  puts 'Running command: '.blue + command
  system(command) or fail "Unable to run: #{command}" # rubocop:disable Style/AndOr
end

namespace :docs do
  task :yard do
    system_or_fail('rm -rf docs/_build/_yard/')
    abort("can't generate YARD") unless system('yard -p docs/_yard/custom_templates -f rst')
  end

  task :sphinx do
    system_or_fail('rm -rf docs/api/')
    system_or_fail('cp -r docs/_build/_yard/ docs/api/')
    abort("can't generate Sphinx docs") unless system('cd docs && make html')
    system_or_fail('cp -r docs/assets/* docs/_build/html/_static/')
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

# Regenerate CHANGELOG.md from the commit history with git-cliff
# (https://git-cliff.org; `brew install git-cliff`). Run after merging PRs to
# refresh [Unreleased]; pass the release tag to finalize a version section:
#   rake "changelog[v12.0.0.beta.7]"
desc 'Regenerate CHANGELOG.md from commits (git-cliff)'
task :changelog, [:tag] do |_task, args|
  cmd = %w[git cliff]
  if (tag = args[:tag])
    tag.match?(/\Av\d[\w.-]*\z/) or raise "Invalid tag #{tag.inspect} (expected e.g. v12.0.0.beta.7)" # rubocop:disable Style/AndOr
    cmd += ['--tag', tag]
  end
  # Pass args to sh as an array — no shell, so the tag can't inject commands.
  sh(*cmd, '-o', 'CHANGELOG.md')
end

task default: ['spec']
