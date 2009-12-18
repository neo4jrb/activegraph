require 'rubygems'
require 'neo4j'
include Neo4j


# The challenge this time is to traverse into friends of friends (or even deeper) and find people with something in common.
# Based on this we can distill someone the user might know, or could be interested in knowing.
# The persons in our social network all have different values for two features, feat1 and feat2.
# The idea of the solution presented here is to keep track of the features that are common in each branch of the traversal
# and to stop when there is nothing in common any more or the maximum distance has been reached.
def you_might_know(node, matches, max_distance)
  buddies = [*node.rels.both(:knows).nodes]
  find_friends(node, [node], matches, 1, max_distance, buddies)
end

def find_friends(root_node, path, matches, depth, max_distance, buddies)
  result = []
  path.last.rels.both(:knows).nodes.each do |node|
    next if (depth > 1 && buddies.include?(node)) || path.include?(node)
    new_matches = matches.find_all{|feature| root_node[feature] == node[feature]}
    next if new_matches.empty?
    new_path = path + [node]
    result = [new_path] + result if depth > 1
    result += find_friends(node, new_path, new_matches, depth + 1, max_distance, buddies) if depth != max_distance
  end
  result
end


puts "-----------------------"
puts "YOU MIGHT KNOW"
puts "-----------------------"


Transaction.new

load "nodes.rb"

node1,node2,node3,node4,node5,node6,node7 = create_nodes

result = you_might_know(node5, [:feat1, :feat2], 4)
result.each do |list|
  puts "You might know nodes"
  list.each {|n| puts n}
end

Transaction.finish
Neo4j.stop


