module Neo4j
  class NodeTraverser
    include Enumerable

    def initialize(from, type, dir)
      @from = from
      @type = org.neo4j.graphdb.DynamicRelationshipType.withName(type.to_s)
      @dir = case dir
               when :outgoing  then org.neo4j.graphdb.Direction::OUTGOING
               when :both  then org.neo4j.graphdb.Direction::BOTH
               when :incoming then org.neo4j.graphdb.Direction::INCOMING
               else raise "unknown direction '#{dir}', expects :outgoing, :incoming or :both"
             end
      @depth = 1
      @td = org.neo4j.kernel.impl.traversal.TraversalDescriptionImpl.new.breadth_first().relationships(@type, @dir)
    end


    def <<(other_node)
      raise "Only allowed to create outgoing relationships, please add it on the other node if you want to create an incoming relationship" unless @dir == org.neo4j.graphdb.Direction::OUTGOING
      @from.create_relationship_to(other_node, @type)
    end


    def depth(d)
      @depth = d
      self
    end

    def each
      iter = iterator
      while (iter.hasNext) do
        yield iter.next
      end
    end

    def iterator
      @td = @td.prune(org.neo4j.kernel.Traversal.pruneAfterDepth( @depth ) )
      iter = @td.traverse(@from).nodes.iterator
      iter.next if iter.hasNext
      # don't include the first node'
      iter
    end
  end

end