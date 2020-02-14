require 'neo4j/core/wrappable'

module Neo4j
  module Core
    module Node
      def props
        properties
      end

      # Perhaps we should deprecate this?
      def neo_id
        id
      end

      def ==(other)
        other.is_a?(Node) && neo_id == other.neo_id
      end

      def labels
        @labels ||= super
      end

      def properties
        @properties ||= super
      end
    end
  end
end
