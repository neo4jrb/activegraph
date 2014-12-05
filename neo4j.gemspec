lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'neo4j/version'


Gem::Specification.new do |s|
  s.name     = "neo4j"
  s.version  = Neo4j::VERSION
  s.required_ruby_version = ">= 1.9.1"

  s.authors  = "Andreas Ronge"
  s.email    = 'andreas.ronge@gmail.com'
  s.homepage = "https://github.com/neo4jrb/neo4j/"
  s.rubyforge_project = 'neo4j'
  s.summary = "A graph database for Ruby"
  s.license = 'MIT'
  s.description = <<-EOF
A Neo4j OGM (Object-Graph-Mapper) for use in Ruby on Rails and Rack frameworks heavily inspired by ActiveRecord.
  EOF

  s.require_path = 'lib'
  s.files = Dir.glob("{bin,lib,config}/**/*") + %w(README.md CHANGELOG CONTRIBUTORS Gemfile neo4j.gemspec)
  s.executables = ['neo4j-jars']
  s.has_rdoc = true
  s.extra_rdoc_files = %w( README.md )
  s.rdoc_options = ["--quiet", "--title", "Neo4j.rb", "--line-numbers", "--main", "README.rdoc", "--inline-source"]

  s.add_dependency('orm_adapter', "~> 0.5.0")
  s.add_dependency("activemodel", "~> 4")
  s.add_dependency("activesupport", "~> 4")
  s.add_dependency("railties", "~> 4")
  s.add_dependency('active_attr', "~> 0.8")
  s.add_dependency("neo4j-core", "~> 3.1.0")

  if RUBY_PLATFORM =~ /java/
    s.add_dependency("neo4j-community", '~> 2.0')
  end
end
