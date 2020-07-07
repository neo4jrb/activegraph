lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'active_graph/version'

Gem::Specification.new do |s|
  s.name     = 'activegraph'
  s.version  = ActiveGraph::VERSION

  s.required_ruby_version = '>= 2.5'

  s.authors  = 'Andreas Ronge, Brian Underwood, Chris Grigg, Heinrich Klobuczek'
  s.email    = 'andreas.ronge@gmail.com, public@brian-underwood.codes, chris@subvertallmedia.com, heinrich@mail.com'
  s.homepage = 'https://github.com/neo4jrb/activegraph/'
  s.summary = 'A graph database for Ruby'
  s.license = 'MIT'
  s.description = <<-DESCRIPTION
A Neo4j OGM (Object-Graph-Mapper) for Ruby heavily inspired by ActiveRecord.
DESCRIPTION

  s.require_path = 'lib'
  s.files = Dir.glob('{bin,lib,config}/**/*') + %w(README.md CHANGELOG.md CONTRIBUTORS Gemfile activegraph.gemspec)
  s.executables = []
  s.extra_rdoc_files = %w( README.md )
  s.rdoc_options = ['--quiet', '--title', 'Neo4j.rb', '--line-numbers', '--main', 'README.rdoc', '--inline-source']
  s.metadata = {
    'homepage_uri' => 'http://neo4jrb.io/',
    'changelog_uri' => 'https://github.com/neo4jrb/activegraph/blob/master/CHANGELOG.md',
    'source_code_uri' => 'https://github.com/neo4jrb/activegraph/',
    'bug_tracker_uri' => 'https://github.com/neo4jrb/activegraph/issues'
  }

  s.add_dependency('activemodel', '>= 4.0')
  s.add_dependency('activesupport', '>= 4.0')
  s.add_dependency('i18n', '!= 1.3.0') # version 1.3.0 introduced a bug with `symbolize_key`
  s.add_dependency('orm_adapter', '~> 0.5.0')
  s.add_development_dependency('guard')
  s.add_development_dependency('guard-rspec')
  s.add_development_dependency('guard-rubocop')
  s.add_development_dependency('neo4j-rake_tasks', '>= 0.3.0')
  s.add_development_dependency("neo4j-#{ENV['driver'] == 'java' ? 'java' : 'ruby'}-driver", '~> 1.7.0')
  s.add_development_dependency('os')
  s.add_development_dependency('pry')
  s.add_development_dependency('railties', '>= 4.0')
  s.add_development_dependency('rake')
  s.add_development_dependency('rubocop', '>= 0.56.0')
  s.add_development_dependency('yard')
  s.add_development_dependency('dryspec')
end
