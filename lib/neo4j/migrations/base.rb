module Neo4j
  module Migrations
    class Base < ::Neo4j::Migration
      include Neo4j::Migrations::Helpers
      include Neo4j::Migrations::Helpers::Schema
      include Neo4j::Migrations::Helpers::IdProperty
      include Neo4j::Migrations::Helpers::Relationships

      def initialize(migration_id)
        @migration_id = migration_id
      end

      def migrate(method)
        Benchmark.realtime do
          ActiveBase.run_transaction(transactions?) do
            if method == :up
              log_queries { up }
              SchemaMigration.create!(migration_id: @migration_id)
            else
              log_queries { down }
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

      private

      def log_queries
        subscriber = Neo4j::Core::CypherSession::Adaptors::Base.subscribe_to_query(&method(:output))
        yield
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
      end
    end
  end
end
