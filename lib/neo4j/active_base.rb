module Neo4j
  # To contain any base login for ActiveNode/ActiveRel which
  # is external to the main classes
  module ActiveBase
    class << self
      def current_session
        SessionRegistry.current_session
      end

      def set_current_session(session)
        SessionRegistry.current_session = session
      end

      def set_current_session_by_adaptor(adaptor)
        set_current_session(Neo4j::Core::CypherSession.new(adaptor))
      end

      def run_transaction(run_in_tx = true)
        Neo4j::Transaction.run(current_session, run_in_tx) do |tx|
          yield tx
        end
      end

      def new_query(options = {})
        Neo4j::Core::Query.new({session: current_transaction || current_session}.merge(options))
      end

      # For making schema changes in a separate session
      # So that we don't have issues with data and schema changes
      # in the same transaction
      def schema_session
        if current_session
          adaptor = current_session.instance_variable_get('@adaptor')
          SessionRegistry.schema_session = Neo4j::Core::CypherSession.new(adaptor)
        end
      end

      def current_transaction
        Neo4j::Transaction.current_for(current_session)
      end
    end
  end
end
