module Neo4j
  module Migrations
    class SchemaMigration
      include Neo4j::ActiveNode

      property :migration_id, type: String, constraint: :unique

      validates :migration_id, presence: true, uniqueness: true
    end
  end
end
