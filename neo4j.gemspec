lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'neo4j/version'


Gem::Specification.new do |s|
  s.name     = "neo4j"
  s.version  = Neo4j::VERSION
  s.required_ruby_version = ">= 1.9.1"

  s.authors  = "Andreas Ronge"
  s.email    = 'andreas.ronge@gmail.com'
  s.homepage = "http://github.com/andreasronge/neo4j/tree"
  s.rubyforge_project = 'neo4j'
  s.summary = "A graph database for Ruby"
  s.license = 'MIT'
  s.description = <<-EOF
You can think of Neo4j as a high-performance graph engine with all the features of a mature and robust database.
The programmer works with an object-oriented, flexible network structure rather than with strict and static tables 
yet enjoys all the benefits of a fully transactional, enterprise-strength database.
It comes included with the Apache Lucene document database.
  EOF

  s.require_path = 'lib'
  s.files = Dir.glob("{bin,lib,config}/**/*") + %w(README.md CHANGELOG CONTRIBUTORS Gemfile neo4j.gemspec)
  s.executables = ['neo4j-jars']
  s.has_rdoc = true
  s.extra_rdoc_files = %w( README.md )
  s.rdoc_options = ["--quiet", "--title", "Neo4j.rb", "--line-numbers", "--main", "README.rdoc", "--inline-source"]

  s.add_dependency('orm_adapter', "~> 0.5.0")
  s.add_dependency("activemodel", "~> 4")
  s.add_dependency("railties", "~> 4")
  s.add_dependency('active_attr', "~> 0.8")
  s.add_dependency("neo4j-core", "= 3.0.0.alpha.13")

  if RUBY_PLATFORM =~ /java/
    s.add_dependency("neo4j-community", '~> 2.0.0')
  end
end
