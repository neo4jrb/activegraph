$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")

require 'rubygems'
require 'neo4j'
require 'neo4j/extensions/activemodel'

class Person
  include Neo4j::NodeMixin
  include ActiveModel::Serializers::JSON
  include ActiveModel::Serializers::Xml

  property :first_name
  property :last_name

end


Neo4j::Transaction.run do
  person = Person.new :first_name => 'jimmy', :last_name => 'smith'
  
  puts "HASH: #{person.serializable_hash}"
  puts "JSON: #{person.to_json}"
  puts "XML : #{person.to_xml}"

end
