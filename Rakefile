$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

require "rspec-apigen/version"


desc "clean all, delete all files that are not in git"
task :clean_all do

  system "git clean -df"
end

desc "create the gemspec"
task :build => :clean_all do
  system "gem build rspec-apigen.gemspec"
end
 
desc "release gem to gemcutter"
task :release => :build do
  assert_committed
  system "gem push rspec-apigen-#{RSpec::ApiGen::VERSION}.gem"
end

def assert_committed
  status = %x{git status}
  fail("Can't release gem unless everything is committed") unless status =~ /nothing to commit \(working directory clean\)|nothing added to commit but untracked files present/
end