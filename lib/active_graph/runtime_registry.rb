require 'active_support/isolated_execution_state'

module ActiveGraph
  module RuntimeRegistry
    class Stats
      attr_accessor :db_runtime

      def initialize
        @db_runtime = 0.0
      end

      def reset_runtime
        db_runtime_was = @db_runtime
        @db_runtime = 0.0
        db_runtime_was
      end
    end

    extend self

    def call(_name, start, finish, _id, _payload)
      stats.db_runtime += (finish - start) * 1_000.0
    end

    def stats
      ActiveSupport::IsolatedExecutionState[:active_graph_runtime] ||= Stats.new
    end

    def reset
      stats.reset_runtime
    end
  end

  ActiveSupport::Notifications.monotonic_subscribe(
    'neo4j.core.bolt.request',
    RuntimeRegistry
  )
end