module Neo4j
  class RelationshipTraverser
    include Enumerable

    def initialize(node, type)
      @node = node
      @type = type && org.neo4j.graphdb.DynamicRelationshipType.withName(type.to_s)
      both # return both incoming and outgoing relationship by default
    end

    def each
      iter = iterator
      while (iter.hasNext) do
        yield iter.next
      end
    end

    def iterator
      if @type
        @node.get_relationships(@type, @dir).iterator
      else
        @node.get_relationships(@dir).iterator
      end
    end

    def both
      @dir = org.neo4j.graphdb.Direction::BOTH
    end

    def incoming
      @dir = org.neo4j.graphdb.Direction::INCOMING
    end

    def outgoing
      @dir = org.neo4j.graphdb.Direction::OUTGOING
    end

  end


  module Relationship
    def outgoing(type)
      NodeTraverser.new(self, type, :outgoing)
    end

    def rels(type=nil)
      RelationshipTraverser.new(self, type)
    end

  end

end