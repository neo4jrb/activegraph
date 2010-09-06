module Neo4j
  class NodeTraverser
    include Enumerable

    def initialize(from, type, dir)
      @type = org.neo4j.graphdb.DynamicRelationshipType.withName(type.to_s)
      @from = from
      @td = org.neo4j.kernel.impl.traversal.TraversalDescriptionImpl.new
      @td.breadth_first()
      @td.relationships(@type)
    end

    def <<(other_node)
      @from.create_relationship_to(other_node, @type)
    end

    def first
      find { true }
    end

    def each
      iter = iterator
      while (iter.hasNext) do
        yield iter.next
      end
    end

    def iterator
      iter = @td.traverse(@from).nodes.iterator
      iter.next if iter.hasNext
      # don't include the first node'
      iter
    end
  end

end