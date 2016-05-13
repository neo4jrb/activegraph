module Neo4j
  module Migrations
    class Base < ::Neo4j::Migration
      include Neo4j::Migrations::Helpers

      def initialize(migration_id)
        @migration_id = migration_id
      end

      def migrate(method)
        Benchmark.realtime do
          transactions? ? migrate_with_transactions(method) : migrate_without_transactions(method)
        end
      end

      def up
        fail NotImplementedError
      end

      def down
        fail NotImplementedError
      end

      protected

      def migrate_with_transactions(method)
        Neo4j::Transaction.run do
          migrate_without_transactions(method)
        end
      end

      def migrate_without_transactions(method)
        if method == :up
          up
          SchemaMigration.create!(migration_id: @migration_id)
        else
          down
          SchemaMigration.find_by!(migration_id: @migration_id).destroy
        end
      end
    end
  end
end
