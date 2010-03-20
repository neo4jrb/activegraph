$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")

require 'rubygems'
require 'neo4j'
require 'neo4j/extensions/activemodel'

class Person
  include Neo4j::NodeMixin
  include ActiveModel::Validations

  property :first_name
  property :last_name

  validates_presence_of :first_name, :last_name
end


Neo4j::Transaction.run do
  person = Person.new

  puts person.valid?
  puts  person.errors.inspect
  person.first_name = "Hej"
  person.last_name = "hop"
  puts person.valid?
end
