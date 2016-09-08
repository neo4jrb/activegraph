module Neo4j
  module Migrations
    extend ActiveSupport::Autoload
    autoload :Helpers
    autoload :MigrationFile
    autoload :Base
    autoload :Runner
    autoload :SchemaMigration

    class << self
      def check_for_pending_migrations!
        runner = Neo4j::Migrations::Runner.new
        fail ::Neo4j::PendingMigrationError if runner.pending_migrations?
      end

      attr_accessor :currently_running_migrations

      def maintain_test_schema!
        Neo4j::Migrations::Runner.new(silenced: true).all
      end
    end
  end
end
