module ActiveGraph
  module Migrations
    class SchemaMigration
      include ActiveGraph::Node
      id_property :migration_id
      property :migration_id, type: String
      property :incomplete, type: Boolean

      def <=>(other)
        migration_id <=> other.migration_id
      end
    end
  end
end
