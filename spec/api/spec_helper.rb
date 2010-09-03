begin
  require "bundler/setup"
rescue Exception => e
  if defined? Bundler
    puts "Type 'bundle install' to download the required gem(s)"
  else
    puts "Please install bundler version > 1.0.0 and type 'bundle install'"
  end
  raise e
end


require 'rspec'
require 'rspec-apigen'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "..", "lib")

require 'neo4j'


class DummyNode
  attr_accessor :props
  def initialize
    @props = {}
  end

  def set_property(p,v)
    @props[p] = v
  end
end


# http://blog.davidchelimsky.net/2010/07/01/rspec-2-documentation/
# http://asciicasts.com/episodes/157-rspec-matchers-macros
#http://kpumuk.info/ruby-on-rails/my-top-7-rspec-best-practices/
# http://eggsonbread.com/2010/03/28/my-rspec-best-practices-and-tips/
# http://www.slideshare.net/gsterndale/straight-up-rspec
#org.neo4j.kernel.impl.core.NodeProxy.class_eval do
#end


