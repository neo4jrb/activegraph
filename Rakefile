#$:.unshift('lib')

require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rake/rdoctask'
require 'spec/version'
require 'spec/rake/spectask'
require 'rake/gempackagetask'

task :default => :spec

desc "spec"
Spec::Rake::SpecTask.new do |t|
  t.libs << "test"
  t.libs << "lib"
  #    t.rcov = true # have not got RCov working with JRuby yet - but it should ...
  t.spec_files = FileList['test/**/*_spec.rb']
  #    t.warning = true
  t.spec_opts = ['--format specdoc', '--color']
  # t.spec_opts = ['--format html:../doc/output/report.html'] #,'--backtrace']
end


desc 'Generate RDoc'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = '../doc/output/rdoc'
  rdoc.options << '--title' << 'Neo' << '--line-numbers' << '--inline-source' << '--main' << 'README'
  rdoc.rdoc_files.include('README.rdoc', 'TODO', 'lib/**/*.rb')
end


##############################################################################
# PACKAGING & INSTALLATION
##############################################################################
 
# What files/dirs should 'rake clean' remove?
CLEAN.include ["*.gem", "pkg", "rdoc", "coverage", "tools/*.png"]
 
# The file list used to package tarballs, gems, and for generating the xmpp4r.gemspec.
PKG_FILES = %w( README.rdoc TODO Rakefile neo4j.gemspec ) + Dir["{lib,test}/**/*"]
 
spec = Gem::Specification.new do |s|
  s.name = "neo4j"
  s.version = '0.0.3'
  s.authors = "Andreas Ronge"
  s.homepage = "http://github.com/andreasronge/neo4j/tree"
  s.summary = "A graph database for JRuby"
  s.description = s.summary
 # s.platform = Gem::Platform::CURRENT
  s.require_path = 'lib'
  s.executables = []
  s.files = PKG_FILES
  s.test_files = []
 
  # rdoc
  s.has_rdoc = true
  s.extra_rdoc_files = %w( README.rdoc  )
  s.rdoc_options = ["--quiet", "--title", "neo4j and lucene documentation", "--opname", "index.html", "--line-numbers", "--main", "README.rdoc", "--inline-source"]
 
  s.required_ruby_version = ">= 1.8.4"
 
end
 
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
  pkg.need_tar = true
end
 
# also keep the gemspec up to date each time we package a tarball or gem
task :package => ['gem:update_gemspec']
task :gem => ['gem:update_gemspec']
 
namespace :gem do
 
  desc "Run :package and install the .gem locally"
  task :install => [:update_gemspec, :package] do
    sh %{gem install --local pkg/neo4j-#{spec.version}.gem --no-rdoc --no-ri}
  end
 
  desc "Run :clean and uninstall the .gem"
  task :uninstall => :clean do
    sh %{sudo gem uninstall neo4j}
  end
 
  # Thanks to the Merb project for this code.
  desc "Update Github Gemspec"
  task :update_gemspec do
    skip_fields = %w(new_platform original_platform)
    integer_fields = %w(specification_version)
 
    result = "# WARNING : RAKE AUTO-GENERATED FILE. DO NOT MANUALLY EDIT!\n"
    result << "# LAST UPDATED : #{Time.now.to_s}\n#\n"
    result << "# RUN : 'rake gem:update_gemspec'\n\n"
    result << "Gem::Specification.new do |s|\n"
    spec.instance_variables.each do |ivar|
      value = spec.instance_variable_get(ivar)
      name = ivar.split("@").last
      next if skip_fields.include?(name) || value.nil? || value == "" || (value.respond_to?(:empty?) && value.empty?)
      if name == "dependencies"
        value.each do |d|
          dep, *ver = d.to_s.split(" ")
          result << " s.add_dependency #{dep.inspect}, #{ver.join(" ").inspect.gsub(/[()]/, "")}\n"
        end
      else
        case value
        when Array
          value = name != "files" ? value.inspect : value.inspect.split(",").join(",\n")
        when String
          value = value.to_i if integer_fields.include?(name)
          value = value.inspect
        else
          value = value.to_s.inspect
        end
        result << " s.#{name} = #{value}\n"
      end
    end
    result << "end"
    File.open(File.join(File.dirname(__FILE__), "#{spec.name}.gemspec"), "w"){|f| f << result}
  end
 
end
