require 'active_support/per_thread_registry'

module Neo4j
  module ActiveBase
    # Provides a simple API to manage sessions in a thread-safe manner
    class SessionRegistry
      extend ActiveSupport::PerThreadRegistry

      attr_accessor :current_session
    end
  end
end
