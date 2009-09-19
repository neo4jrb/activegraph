require 'rubygems'
require 'neo4j'

puts "-----------------------"
puts "YOU MIGHT KNOW"
puts "-----------------------"

def you_might_know(node, matches, max_distance)
  buddies = node.relationships.both(:knows).nodes.to_a
  find_friends(node, [node], matches, 1, max_distance, buddies)
end

def find_friends(root_node, path, matches, depth, max_distance, buddies)
  result = []
  path.last.relationships.both(:knows).nodes.each do |node|
    next if (depth > 1 && buddies.include?(node)) || path.include?(node)
    new_matches = matches.find_all{|feature| root_node[feature] == node[feature]}
    next if new_matches.empty?
    new_path = path + [node]
    result = [new_path] + result if depth > 1
    result += find_friends(node, new_path, new_matches, depth + 1, max_distance, buddies) if depth != max_distance
  end
  result
end


include Neo4j

# Add a to string method printing the node name
class Node
  include Neo4j::NodeMixin

  def to_s
    "Node #{self[:name]}"
  end
end

Transaction.new
node1 = Node.new; node1[:feat1] = 'a'; node1[:feat2] = 'b'; node1[:name] = 1
node2 = Node.new; node2[:feat1] = 'a'; node2[:feat2] = 'b'; node2[:name] = 2
node3 = Node.new; node3[:feat1] = 'a'; node3[:feat2] = 'd'; node3[:name] = 3
node4 = Node.new; node4[:feat1] = 'c'; node4[:feat2] = 'd'; node4[:name] = 4
node5 = Node.new; node5[:feat1] = 'a'; node5[:feat2] = 'b'; node5[:name] = 5
node6 = Node.new; node6[:feat1] = 'a'; node6[:feat2] = 'b'; node6[:name] = 6
node7 = Node.new; node7[:feat1] = 'a'; node7[:feat2] = 'b'; node7[:name] = 7

node1.relationships.outgoing(:knows) << node3
node2.relationships.outgoing(:knows) << node1
node2.relationships.outgoing(:knows) << node4
node3.relationships.outgoing(:knows) << node5
node3.relationships.outgoing(:knows) << node4
node3.relationships.outgoing(:knows) << node6
node4.relationships.outgoing(:knows) << node7
node5.relationships.outgoing(:knows) << node6
node5.relationships.outgoing(:knows) << node1
node6.relationships.outgoing(:knows) << node1

result = you_might_know(node5, [:feat1, :feat2], 4)
result.each do |list|
  puts "You might know nodes"
  list.each {|n| puts n}
end

Transaction.finish
#Neo4j.stop

#class YouMightKnow
#{
#    List<List<Node>> result = new ArrayList<List<Node>>();
#    int maxDistance;
#    String[] features;
#    Object[] values;
#    Set<Node> buddies = new HashSet<Node>();
#
#    YouMightKnow( Node node, String[] features, int maxDistance )
#    {
#        this.features = features;
#        this.maxDistance = maxDistance;
#        values = new Object[features.length];
#        List<Integer> matches = new ArrayList<Integer>();
#        for ( int i = 0; i < features.length; i++ )
#        {
#            values[i] = node.getProperty( features[i] );
#            matches.add( i );
#        }
#        for ( Relationship rel : node.getRelationships( RelationshipTypes.KNOWS ) )
#        {
#            buddies.add( rel.getOtherNode( node ) );
#        }
#        findFriends( Arrays.asList( new Node[] { node } ), matches, 1 );
#    }

#    void findFriends( List<Node> path, List<Integer> matches, int depth )
#    {
#        Node prevNode = path.get( path.size() - 1 );
#        for ( Relationship rel : prevNode.getRelationships( RelationshipTypes.KNOWS ) )
#        {
#            Node node = rel.getOtherNode( prevNode );
#            if ( (depth > 1 && buddies.contains( node )) || path.contains( node ) )
#            {
#                continue;
#            }
#            List<Integer> newMatches = new ArrayList<Integer>();
#            for ( int match : matches )
#            {
#                if ( node.getProperty( features[match] ).equals( values[match] ) )
#                {
#                    newMatches.add( match );
#                }
#            }
#            if ( newMatches.size() > 0 )
#            {
#                List<Node> newPath = new ArrayList<Node>( path );
#                newPath.add( node );
#                if ( depth > 1 )
#                {
#                    result.add( newPath );
#                }
#                if ( depth != maxDistance )
#                {
#                    findFriends( newPath, newMatches, depth + 1 );
#                }
#            }
#        }
#    }
#}
