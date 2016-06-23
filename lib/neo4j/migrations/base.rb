module Neo4j
  module Migrations
    class Base < ::Neo4j::Migration
      include Neo4j::Migrations::Helpers
      include Neo4j::Migrations::Helpers::Schema
      include Neo4j::Migrations::Helpers::IdProperty

      def initialize(migration_id)
        @migration_id = migration_id
      end

      def migrate(method)
        Benchmark.realtime do
          ActiveBase.run_transaction(transactions?) do
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

      def up
        fail NotImplementedError
      end

      def down
        fail NotImplementedError
      end
    end
  end
end
