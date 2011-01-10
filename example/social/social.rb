require "rubygems"
require "bundler/setup"
require 'fileutils'
require 'neo4j'

# Remove old database if there is one
FileUtils.rm_rf Neo4j::Config[:storage_path]  # this is the default location of the database

require 'model'
require 'data'


city = City.find_by_name('seattle')
andreas = Person.find_by_name 'andreas'
film = Film.find_by_title("dexter")

# Find andreas friends of friends depth 5 living in seattle and likes the dexter film
puts andreas.outgoing(:friends).depth(5).find_all{|friend| friend.city == city && friend.likes.include?(film)}.to_a.join(', ')


