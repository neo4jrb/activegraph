module Neo4j


  module Relationship
    def outgoing(type)
      NodeTraverser.new(self, type, :outgoing)
    end

    def incoming(type)
      NodeTraverser.new(self, type, :incoming)
    end

    def both(type)
      NodeTraverser.new(self, type, :both)
    end

    def rels(*type)
      RelationshipTraverser.new(self, type, :both)
    end

  end

end