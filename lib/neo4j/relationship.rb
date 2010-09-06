module Neo4j
  module Relationship
    def outgoing(type)
      NodeTraverser.new(self, type, :outgoing)
    end
  end

end