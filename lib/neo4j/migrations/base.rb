module Neo4j
  module Migrations
    class Base
      include Neo4j::Migrations::Helpers
      include Neo4j::Migrations::Helpers::Schema
      include Neo4j::Migrations::Helpers::IdProperty
      include Neo4j::Migrations::Helpers::Relationships

      def initialize(migration_id, options = {})
        @migration_id = migration_id
        @silenced = options[:silenced]
      end

      def migrate(method)
        Benchmark.realtime do
          method == :up ? migrate_up : migrate_down
        end
      end

      def up
        fail NotImplementedError
      end

      def down
        fail NotImplementedError
      end

      private

      def migrate_up
        schema = SchemaMigration.create!(migration_id: @migration_id, incomplete: true)
        begin
          run_migration(:up)
        rescue StandardError => e
          schema.destroy if transactions?
          handle_migration_error!(e)
        else
          schema.update!(incomplete: nil)
        end
      end

      def migrate_down
        schema = SchemaMigration.find_by!(migration_id: @migration_id)
        schema.update!(incomplete: true)
        begin
          run_migration(:down)
        rescue StandardError => e
          schema.update!(incomplete: nil) if transactions?
          handle_migration_error!(e)
        else
          schema.destroy
        end
      end

      def run_migration(direction)
        migration_transaction { log_queries { public_send(direction) } }
      end

      def handle_migration_error!(e)
        fail e unless e.message =~ /Cannot perform data updates in a transaction that has performed schema updates./
        fail MigrationError,
             "#{e.message}. Please add `disable_transactions!` in your migration file."
      end

      def migration_transaction(&block)
        ActiveBase.run_transaction(transactions?, &block)
      end

      def log_queries
        subscriber = Neo4j::Core::CypherSession::Adaptors::Base.subscribe_to_query(&method(:output))
        yield
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
      end
    end
  end
end
