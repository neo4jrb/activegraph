#  require "bundler/setup"
require 'rspec'
require 'rspec-apigen'
require 'fileutils'

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

  def property?(p)
    !@props[p].nil?
  end
end
