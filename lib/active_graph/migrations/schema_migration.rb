module ActiveGraph
  module Migrations
    class SchemaMigration
      include ActiveGraph::Node
      id_property :migration_id
      property :migration_id, type: String
      property :incomplete, type: Boolean
    end
  end
end
