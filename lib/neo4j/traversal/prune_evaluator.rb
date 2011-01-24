module Neo4j
  module Traversal
    class PruneEvaluator  # :nodoc:
      include org.neo4j.graphdb.traversal.PruneEvaluator
      def initialize(proc)
        @proc = proc
      end

      def prune_after(path)
        @proc.call(path)
      end
    end
  end
end
