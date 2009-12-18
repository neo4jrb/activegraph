# -----------------------------------------------------------------------------

# Add a to string method printing the node name
class Node
  include Neo4j::NodeMixin

  def to_s
    "Node #{self[:name]}"
  end
end

def create_nodes
  node1 = Node.new; node1[:feat1] = 'a'; node1[:feat2] = 'b'; node1[:name] = 1
  node2 = Node.new; node2[:feat1] = 'a'; node2[:feat2] = 'b'; node2[:name] = 2
  node3 = Node.new; node3[:feat1] = 'a'; node3[:feat2] = 'd'; node3[:name] = 3
  node4 = Node.new; node4[:feat1] = 'c'; node4[:feat2] = 'd'; node4[:name] = 4
  node5 = Node.new; node5[:feat1] = 'a'; node5[:feat2] = 'b'; node5[:name] = 5
  node6 = Node.new; node6[:feat1] = 'a'; node6[:feat2] = 'b'; node6[:name] = 6
  node7 = Node.new; node7[:feat1] = 'a'; node7[:feat2] = 'b'; node7[:name] = 7

  node1.rels.outgoing(:knows) << node3
  node2.rels.outgoing(:knows) << node1
  node2.rels.outgoing(:knows) << node4
  node3.rels.outgoing(:knows) << node5
  node3.rels.outgoing(:knows) << node4
  node3.rels.outgoing(:knows) << node6
  node4.rels.outgoing(:knows) << node7
  node5.rels.outgoing(:knows) << node6
  node5.rels.outgoing(:knows) << node1
  node6.rels.outgoing(:knows) << node1
  
  [node1,node2,node3,node4,node5,node6,node7]
end

