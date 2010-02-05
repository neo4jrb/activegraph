#$:.unshift('lib')

require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'spec/version'
require 'spec/rake/spectask'
require 'rake/gempackagetask'
begin
  require 'hanna/rdoctask'
  $HANNA_DEFINED = true
rescue LoadError => load_error
  require 'rake/rdoctask'
end

#require 'hoe'

require 'lib/neo4j/version'

GEM_NAME = 'neo4j'
PROJECT_SUMMARY= "A graph database for JRuby"
GEM_VERSION =Neo4j::VERSION


task :default => :spec
#
#Hoe.new(GEM_NAME, GEM_VERSION) do |p|
#  p.rubyforge_name = GEM_NAME
#  s.summary = PROJECT_SUMMARY
#end


desc "Flog all Ruby files in lib"
task :flog do
  system("find lib -name '*.rb' | xargs flog")
end


desc "spec"
Spec::Rake::SpecTask.new do |t|
  t.libs << "test"
  t.libs << "lib"
  #  t.rcov = true
  # rest specs requires some other gems - see the rest_spec.rb file
  t.spec_files =  FileList['test/lucene/*_spec.rb'] + FileList['test/neo4j/*_spec.rb'] +
    FileList['test/extensions/**/*_spec.rb'] #  FileList['test/**/*_spec.rb']
  t.spec_opts = ['--format specdoc', '--color']
  # t.spec_opts = ['--format html:../doc/output/report.html'] #,'--backtrace']
end


desc 'Generate RDoc'
Rake::RDocTask.new do |rdoc|
#   rdoc -o doc --inline-source --format=html -T hanna
  rdoc.rdoc_dir = './rdoc'
  rdoc.options << '--title' << "Neo4j v#{Neo4j::VERSION}" << '--line-numbers' << '--inline-source' << '--main' << 'README.rdoc'
  rdoc.options << '--webcvs=http://github.com/andreasronge/neo4j/tree/master/'
  
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('CHANGELOG')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.exclude('lib/neo4j/extensions/*.rb')
  rdoc.rdoc_files.exclude('lib/neo4j/extensions/aggregate/**/*.rb')
end

desc 'Upload documentation to RubyForge.'
task 'upload-docs' do
  sh "scp -r rdoc/* " +
    "ronge@rubyforge.org:/var/www/gforge-projects/neo4j/"
end

##############################################################################
# PACKAGING & INSTALLATION
##############################################################################
 
# What files/dirs should 'rake clean' remove?
CLEAN.include ["*.gem", "pkg", "rdoc", "coverage", "tools/*.png", 'var']
 
# The file list used to package tarballs, gems, and for generating the xmpp4r.gemspec.
PKG_FILES = %w( LICENSE CHANGELOG README.rdoc Rakefile ) + Dir["{lib,test,examples}/**/*"]
 
spec = Gem::Specification.new do |s|
  s.name = GEM_NAME
  s.version = GEM_VERSION
  s.authors = "Andreas Ronge"
  s.email = 'andreas.ronge@gmail.com'
  s.homepage = "http://github.com/andreasronge/neo4j/tree"
  s.rubyforge_project = 'neo4j'
  s.summary = PROJECT_SUMMARY
  s.description = s.summary
  s.require_path = 'lib'
  s.executables = []
  s.files = PKG_FILES
  s.test_files = []
  #s.homepage = 'http://neo4j.rubyforge.org' 
  # rdoc
  s.has_rdoc = true
  s.extra_rdoc_files = %w( README.rdoc )
  s.rdoc_options = ["--quiet", "--title", "Neo4j.rb", "--opname", "index.html", "--line-numbers", "--main", "README.rdoc", "--inline-source"]
 
  s.required_ruby_version = ">= 1.8.4"

  # TODO add those dependencies when there is a new release of sinatra and rack-test (you need to build it your self if running neo4j-rest)
  # s.add_dependency("json_jruby", ">=1.1.6")  rack 1.0.0   sinatra (0.10.1

end
 
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
  pkg.need_tar = true
end
 
# also keep the gemspec up to date each time we package a tarball or gem
#task :package => ['gem:update_gemspec']
#task :gem => ['gem:update_gemspec']
 
namespace :gem do
 
  desc "Run :package and install the .gem locally"
  task :install => [:package] do
    sh %{gem install --local pkg/neo4j-#{spec.version}.gem --no-rdoc --no-ri}
  end
 
  desc "Run :clean and uninstall the .gem"
  task :uninstall => :clean do
    sh %{gem uninstall neo4j}
  end
 
end
