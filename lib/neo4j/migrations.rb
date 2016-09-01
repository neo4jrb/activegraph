module Neo4j
  module Migrations
    extend ActiveSupport::Autoload
    autoload :Helpers
    autoload :MigrationFile
    autoload :Base
    autoload :Runner
    autoload :SchemaMigration

    def self.check_for_pending_migrations!
      runner = Neo4j::Migrations::Runner.new
      fail ::Neo4j::PendingMigrationError if runner.pending_migrations?
    end

    def self.maintain_test_schema!
      Neo4j::Migrations::Runner.new(silenced: true).all
    end
  end
end
