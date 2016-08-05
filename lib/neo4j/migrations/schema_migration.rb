module Neo4j
  module Migrations
    class SchemaMigration
      include Neo4j::ActiveNode
      id_property :migration_id
      property :migration_id, type: String
      property :incomplete, type: Boolean

      def <=>(other)
        migration_id <=> other.migration_id
      end
    end
  end
end
