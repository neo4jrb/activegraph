module Neo4j

  class RelationshipTraverser
    include Enumerable

    def initialize(node, types)
      @node = node
      if types.size > 1
        @types = types.inject([]) { |result, type| result << org.neo4j.graphdb.DynamicRelationshipType.withName(type.to_s) }.to_java(:'org.neo4j.graphdb.RelationshipType')
      elsif types.size == 1
        @type = org.neo4j.graphdb.DynamicRelationshipType.withName(types[0].to_s)
      end

      both
      # return both incoming and outgoing relationship by default
    end

    def each
      iter = iterator
      while (iter.hasNext) do
        yield iter.next
      end
    end

    def iterator
      if @types
        @node.get_relationships(@types).iterator
      elsif @type
        @node.get_relationships(@type, @dir).iterator
      else
        @node.get_relationships(@dir).iterator
      end
    end

    def both
      @dir = org.neo4j.graphdb.Direction::BOTH
      self
    end

    def incoming
      raise "Not allowed calling incoming when finding several relationships types" if @types
      @dir = org.neo4j.graphdb.Direction::INCOMING
      self
    end

    def outgoing
      raise "Not allowed calling outgoing when finding several relationships types" if @types
      @dir = org.neo4j.graphdb.Direction::OUTGOING
      self
    end

  end
end