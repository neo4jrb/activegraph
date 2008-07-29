Gem::Specification.new do |s|
  s.name = "neo4j.rb"
  s.version = "0.0.1"
  s.summary = "Network Database for JRuby"
  s.homepage = "http://github.com/andreasronge/neo4j.rb/tree"
  s.platform = Gem::Platform::RUBY
  s.description = "A Network Database for JRuby."
  s.has_rdoc = true
  s.authors = ['Andreas Ronge']
  candidates = Dir.glob("{bin,docs,lib,test}/**/*")
  s.files = candidates.delete_if do |item|
              item.include?("rdoc")
            end
  s.require_path = "lib"
end