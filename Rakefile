# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'spec/rake/spectask'


#task :default => :spec

desc "spec"
Spec::Rake::SpecTask.new do |t|
    t.libs << "test"
    t.libs << "lib"
    t.spec_files = FileList['test/**/*_spec.rb']
    t.warning = true
#    t.rcov = true
  end
