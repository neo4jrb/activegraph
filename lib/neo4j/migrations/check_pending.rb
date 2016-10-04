module Neo4j
  module Migrations
    class CheckPending
      def initialize(app)
        @app = app
        @last_check = 0
      end

      def call(env)
        mtime = Neo4j::Migrations::Runner.latest_migration.version.to_i
        if @last_check < mtime
          Neo4j::Migrations.check_for_pending_migrations!
          @last_check = mtime
        end
        @app.call(env)
      end
    end
  end
end
