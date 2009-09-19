class YouMightKnow
{
    List<List<Node>> result = new ArrayList<List<Node>>();
    int maxDistance;
    String[] features;
    Object[] values;
    Set<Node> buddies = new HashSet<Node>();

    YouMightKnow( Node node, String[] features, int maxDistance )
    {
        this.features = features;
        this.maxDistance = maxDistance;
        values = new Object[features.length];
        List<Integer> matches = new ArrayList<Integer>();
        for ( int i = 0; i < features.length; i++ )
        {
            values[i] = node.getProperty( features[i] );
            matches.add( i );
        }
        for ( Relationship rel : node.getRelationships( RelationshipTypes.KNOWS ) )
        {
            buddies.add( rel.getOtherNode( node ) );
        }
        findFriends( Arrays.asList( new Node[] { node } ), matches, 1 );
    }

    void findFriends( List<Node> path, List<Integer> matches, int depth )
    {
        Node prevNode = path.get( path.size() - 1 );
        for ( Relationship rel : prevNode.getRelationships( RelationshipTypes.KNOWS ) )
        {
            Node node = rel.getOtherNode( prevNode );
            if ( (depth > 1 && buddies.contains( node )) || path.contains( node ) )
            {
                continue;
            }
            List<Integer> newMatches = new ArrayList<Integer>();
            for ( int match : matches )
            {
                if ( node.getProperty( features[match] ).equals( values[match] ) )
                {
                    newMatches.add( match );
                }
            }
            if ( newMatches.size() > 0 )
            {
                List<Node> newPath = new ArrayList<Node>( path );
                newPath.add( node );
                if ( depth > 1 )
                {
                    result.add( newPath );
                }
                if ( depth != maxDistance )
                {
                    findFriends( newPath, newMatches, depth + 1 );
                }
            }
        }
    }
}