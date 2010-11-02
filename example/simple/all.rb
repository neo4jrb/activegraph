require 'person'

puts "List of all nodes:"
Neo4j.all_nodes.each do |node|
  puts " #{node}" unless node == Neo4j.ref_node
end