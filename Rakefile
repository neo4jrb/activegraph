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

# Refresh CHANGELOG.md's [Unreleased] section from conventional commits with
# git-cliff (https://git-cliff.org; `brew install git-cliff`). Non-destructive:
# generates only the new (unreleased) entries and inserts them under the
# preamble, leaving the hand-written history below untouched — activegraph's
# pre-conventional-commit history can't be regenerated. Pass the release tag to
# finalize the section as a version at release time:
#   rake "changelog[v12.0.0.beta.8]"
desc 'Refresh CHANGELOG.md [Unreleased] from conventional commits (git-cliff)'
task :changelog, [:tag] do |_task, args|
  cmd = %w[git cliff --unreleased --strip all]
  if (tag = args[:tag])
    # array form (no shell) means the tag can't inject commands
    tag.match?(/\Av\d[\w.-]*\z/) or raise "Invalid tag #{tag.inspect} (expected e.g. v12.0.0.beta.8)" # rubocop:disable Style/AndOr
    cmd += ['--tag', tag]
  end
  require 'open3'
  section, stderr, status = Open3.capture3(*cmd)
  warn stderr unless stderr.empty?  # surface git-cliff's own warnings (e.g. skipped commits)
  abort "git-cliff failed (exit #{status.exitstatus})" unless status.success?
  section = section.strip
  # git-cliff still emits a bare `## [<id>]` heading with no entries when nothing
  # matched — only touch the file when there's at least one entry.
  abort 'git-cliff produced no entries (no conventional commits since the last release).' unless section.match?(/^- /)
  # generated heading is `## [Unreleased]`, or `## [<version>]` when a tag is given
  id = section[/\A## \[([^\]]+)\]/, 1]
  changelog = File.read('CHANGELOG.md')
  # drop a stale [Unreleased] and any existing section for the target id (so a
  # re-run at release is idempotent); the lookahead stops at the next heading or
  # end of file, so a trailing section is handled too
  ['Unreleased', id].uniq.each do |heading|
    changelog = changelog.sub(/^## \[#{Regexp.escape(heading)}\].*?(?=^## \[|\z)/m, '')
  end
  changelog = changelog.sub(/^(?=## \[)/, "#{section}\n\n")  # insert under the preamble
  File.write('CHANGELOG.md', changelog)
  puts "Updated CHANGELOG.md:\n#{section}"
end

task default: ['spec']
