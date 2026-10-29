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

VERSION_FILE = 'lib/active_graph/version.rb'.freeze

# Cut a release in one step. The gem version lives in version.rb (single source
# of truth — the release workflow refuses a tag that disagrees with it), so:
#
#   rake release            # release the version already in version.rb
#   rake "release[12.0.2]"  # bump version.rb to 12.0.2 first, then release
#
# It finalizes the CHANGELOG section for the version, commits version.rb +
# CHANGELOG.md and pushes straight to the default branch (sanctioned by the admin
# `always` bypass on the branch ruleset — a changelog/version commit is
# paths-ignored by CI and the changelog is machine-generated, so a PR would add
# process without protection), then — after a y/N gate, since this publishes to
# RubyGems and can't be undone — tags `v<version>` and pushes the tag, which
# triggers .github/workflows/release.yml.
#
# Set RELEASE_YES=1 to skip the confirmation (e.g. from an automated caller).
def cut_release(version_arg) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  # Mutating commands abort loudly on failure; array form means no shell, so
  # nothing here can be shell-injected. `probe` is for boolean probes.
  run = ->(*cmd) { system(*cmd) or abort("✗ command failed: #{cmd.join(' ')}") }
  probe = ->(*cmd) { system(*cmd, out: File::NULL, err: File::NULL) }

  # --- preflight (before touching anything) --------------------------------
  probe.call('git', 'cliff', '--version') or abort '✗ git-cliff not found — `brew install git-cliff`.'
  probe.call('gh', 'auth', 'status') or abort '✗ gh not authenticated — run `gh auth login`.'
  main = `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`.strip
  abort '✗ could not determine the default branch via gh.' if main.empty?
  branch = `git rev-parse --abbrev-ref HEAD`.strip
  abort "✗ not on #{main} (on #{branch}). Releases are cut from #{main}." unless branch == main
  abort '✗ working tree is dirty — commit or stash first.' unless `git status --porcelain`.empty?

  run.call('git', 'fetch', '--quiet', 'origin', main, '--tags')
  if `git rev-parse HEAD`.strip != `git rev-parse origin/#{main}`.strip
    abort "✗ local #{main} differs from origin/#{main} — `git pull` (or push your commits) first."
  end

  # --- resolve + validate the target version (no writes yet) ---------------
  # Decide the version from the arg (a bump) or version.rb, and run every check
  # that can reject the release BEFORE touching version.rb — otherwise a rejected
  # release (e.g. an already-tagged version) would leave the tree dirty and block
  # a clean re-run.
  version = version_arg&.delete_prefix('v') || File.read(VERSION_FILE)[/VERSION = '([^']*)'/, 1] or
    abort "✗ no VERSION in #{VERSION_FILE}."
  version.match?(/\A\d+\.\d+\.\d+(\.[A-Za-z0-9]+)*\z/) or
    abort "✗ invalid version #{version.inspect} (expected e.g. 12.0.2 or 12.1.0.beta.1)."
  tag = "v#{version}"

  # A released version can never be reused on RubyGems, so refuse a taken tag.
  abort "✗ tag #{tag} already exists locally." if probe.call('git', 'rev-parse', '-q', '--verify', "refs/tags/#{tag}")
  abort "✗ #{tag} is already released (tag on origin) — bump the version." \
    unless `git ls-remote --tags origin "refs/tags/#{tag}"`.empty?

  # --- finalize changelog + land the commit on the default branch ----------
  # The changelog task takes the tag explicitly and aborts (without writing)
  # when git-cliff fails or finds no entries, so run it BEFORE bumping
  # version.rb — a changelog failure then leaves the tree clean for a re-run.
  Rake::Task[:changelog].invoke(tag)
  if version_arg
    src = File.read(VERSION_FILE)
    File.write(VERSION_FILE, src.sub(/VERSION = '[^']*'/, "VERSION = '#{version}'"))
  end
  run.call('git', 'add', VERSION_FILE, 'CHANGELOG.md')
  if probe.call('git', 'diff', '--cached', '--quiet')
    puts "• No version/changelog change to commit — #{main} already holds #{tag}'s content."
  else
    # chore(release) is excluded from the changelog (see cliff.toml), so the
    # release commit never shows up in its own CHANGELOG.
    run.call('git', 'commit', '--quiet', '-m', "chore(release): #{tag}")
    run.call('git', 'push', '--quiet', 'origin', main)
    puts "• Pushed #{tag}'s changelog commit to #{main}."
  end

  # --- gate the irreversible publish, then tag -----------------------------
  unless ENV['RELEASE_YES'] == '1'
    print "\nAbout to tag #{tag} and push it — this publishes #{tag} to RubyGems " \
          "and cannot be undone.\nContinue? [y/N] "
    answer = $stdin.gets
    unless answer&.strip&.match?(/\A(y|yes)\z/i)
      abort "Aborted before tagging. #{main} already has the changelog commit; re-run `rake release` when ready."
    end
  end

  run.call('git', 'tag', tag)
  unless system('git', 'push', 'origin', tag)
    # Drop the local tag so the "already exists locally" check doesn't block a
    # re-run; the changelog commit is already on origin, so re-running resumes
    # at the tag step. If origin did receive the tag despite the error, the
    # re-run stops at the "already released" check — the workflow has fired.
    system('git', 'tag', '-d', tag, out: File::NULL)
    abort "✗ pushing #{tag} failed — local tag removed. Re-run `rake release` to retry."
  end
  puts "\n✓ Pushed #{tag}. Release workflow:\n  " \
       'https://github.com/neo4jrb/activegraph/actions/workflows/release.yml'
end

# bundler/gem_tasks defines its own `release` (build + `gem push` with local
# credentials, bypassing the trusted-publishing workflow); replace it outright.
Rake::Task[:release].clear
desc 'Cut a release: finalize CHANGELOG, push the default branch, tag, and trigger publish ' \
     '(version from version.rb; pass one to bump first, e.g. rake "release[12.0.2]")'
task(:release, [:version]) { |_task, args| cut_release(args[:version]) }

task default: ['spec']
