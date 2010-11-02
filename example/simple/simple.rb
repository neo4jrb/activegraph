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
end


# Remove old database if there is one
FileUtils.rm_rf Neo4j::Config[:storage_path]  # this is the default location of the database

# Creating new node
person = Neo4j::Transaction.run { Person.new }

# Setting properties

Neo4j::Transaction.run { person.name = 'kalle'; person.salary = 10000 }

# Setting any properties

Neo4j::Transaction.run { person['an_undefined_property'] = 'hello' }

# Showing all properties as a hash, no transaction needed
puts "Person = #{person.props.inspect}"


# Find all person named kalle
kalle = Person.find('name: kalle').first
puts "Found #{kalle.name}"

# add a friend relationship
Neo4j::Transaction.run { kalle.friends << Person.new(:name => 'sune')}

# find all friends
puts "#{kalle.name} has friends"
kalle.friends.each {|f| puts " has friend #{f.name}"}

