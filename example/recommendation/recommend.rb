require 'rubygems'
require "bundler/setup"
require 'neo4j'

require 'logger' # use default logger
Neo4j::Config[:logger_level] = Logger::ERROR

def likes(node)
  node.outgoing(:likes).to_a
end

def recommend(node)
  # which artists does this person like ?
  i_like             = likes(node)

  # find all other people liking those artists
  other_people_likes = node.both(:likes).depth(2).filter { |f| f.length == 2 }
  # for each of those people sort by the number of matching artists
  # so that the person with the most similar taste is first in the list
  sorted = other_people_likes.sort_by { |p| (likes(p) & i_like).size }.reverse
  # now for each of those people in this list get the composers that I don't like yet
  sorted.map{|person| likes(person) - i_like}.flatten.uniq
end


tx        = Neo4j::Transaction.new
alkan     = Neo4j::Node.new :name => 'Charles-Valentin Alkan'
beethoven = Neo4j::Node.new :name => "Ludwig van Beethoven"
chopin    = Neo4j::Node.new :name => 'Frédéric Chopin'
debussy   = Neo4j::Node.new :name => "Claude Debussy"
elgar     = Neo4j::Node.new :name => "Edward Elgar"
faure     = Neo4j::Node.new :name => "Gabriel Fauré"
gershwin  = Neo4j::Node.new :name => "George Gershwin"

person_1  = Neo4j::Node.new :name => "person 1"
person_2  = Neo4j::Node.new :name => "person 2"
person_3  = Neo4j::Node.new :name => "person 3"
person_4  = Neo4j::Node.new :name => "person 4"

person_1
person_1.outgoing(:likes) << beethoven << chopin << debussy
person_2.outgoing(:likes) << alkan << beethoven  # one similar to person 1
person_3.outgoing(:likes) << chopin << debussy << elgar << faure  # two similar to person 1
person_4.outgoing(:likes) << beethoven << chopin << debussy << gershwin # three similar to person 1
tx.success
tx.finish

puts "Recommend"
recommend(person_1).each {|node| puts node[:name]}