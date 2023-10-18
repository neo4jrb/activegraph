module ActiveGraph
  module Migrations
    class << self
      def check_for_pending_migrations!
        return if ActiveGraph::Config.configuration['skip_migration_check']

        runner = ActiveGraph::Migrations::Runner.new
        pending = runner.pending_migrations
        fail ::ActiveGraph::PendingMigrationError, pending if pending.any?
      end

      attr_accessor :currently_running_migrations

      def maintain_test_schema!
        ActiveGraph::Migrations::Runner.new(silenced: true).all
      end
    end
  end
end
