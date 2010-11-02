require 'person'


if ARGV.size != 2
  puts "ruby add.rb <name> <salary>"
else
  person = Neo4j::Transaction.run do
    Person.new :name => ARGV[0], :salary => ARGV[1].to_i
  end
  puts "Added #{person}"
  value = "andreas" # ARGV[0]
  found = [*Person.find("name:  #{value}")]
  puts "FOUND #{found.join(', ')}"
end

