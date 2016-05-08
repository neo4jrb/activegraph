module Neo4j
  module Migrations
    class Base < ::Neo4j::Migration
      def initialize(migration_id)
        @migration_id = migration_id
      end

      def migrate(method)
        Benchmark.realtime do
          Neo4j::Transaction.run do
            __send__(method)
          end
        end
      end

      def up
        fail NotImplementedError
      end

      def down
        fail NotImplementedError
      end

      protected

      def execute(string)
        Neo4j::Session.query(string).to_a
      end

      private

      # def migrate_up
      #   migration = SchemaMigration.new(migration_id: @migration_id)
      #   if migration.save
      #     output "Running migration #{@migration_id}..."
      #     up
      #   else
      #     output('Already migrated.')
      #   end
      # end

      # def migrate_down
      #   SchemaMigration.find_by(migration_id: @migration_id) && down
      # end
    end
  end
end
