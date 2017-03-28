module Neo4j
  module Migrations
    extend ActiveSupport::Autoload
    autoload :Helpers
    autoload :MigrationFile
    autoload :Base
    autoload :Runner
    autoload :SchemaMigration
    autoload :CheckPending

    class << self
      def check_for_pending_migrations!
        return if Neo4j::Config.configuration['skip_migration_check']

        runner = Neo4j::Migrations::Runner.new
        pending = runner.pending_migrations
        fail ::Neo4j::PendingMigrationError, pending if pending.any?
      end

      attr_accessor :currently_running_migrations

      def maintain_test_schema!
        Neo4j::Migrations::Runner.new(silenced: true).all
      end
    end
  end
end
