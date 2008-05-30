#$:.unshift('lib')

require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rake/rdoctask'
require 'spec/version'
require 'spec/rake/spectask'

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
