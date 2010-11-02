require "rubygems"
require "bundler/setup"
require 'fileutils'
require 'neo4j'

class Person
  include Neo4j::NodeMixin

  # define Neo4j properties
  property :name, :salary, :age, :country

  # define an one way relationship to any other node
  has_n :friends

  # adds a Lucene index on the following properties
  index :name
  index :salary
  index :age
  index :country

  def to_s
    "Person name: '#{name}'"
  end
end

