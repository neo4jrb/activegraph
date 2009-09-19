require 'rubygems'
require 'neo4j'
require 'neo4j/extensions/graph_algo'
include Neo4j

# In this case we want to know the possible paths from one person in a social network to an other.
# With those paths at hand we can do things similar to the "How you're connected to N.N." feature of LinkedIn.



Transaction.new

load "nodes.rb"

node1,node2,node3,node4,node5,node6,node7 = create_nodes

found_nodes = GraphAlgo.all_simple_paths.from(node1).both(:knows).to(node7).depth(4).as_nodes
puts "Nodes between #{node1} and #{node7}"
found_nodes.each do |path|
  puts "path"
  path.each {|node| puts " #{node}" }
end

sorted = found_nodes.sort_by{|path| 10 - path.size}

puts "sorted: "
sorted.each do |path|
  puts "path"
  path.each {|node| puts " #{node}" }
end

Transaction.finish

Neo4j.stop