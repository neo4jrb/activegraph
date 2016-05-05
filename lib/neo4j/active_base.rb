module Neo4j
  # To contain any base login for ActiveNode/ActiveRel which
  # is external to the main classes
  module ActiveBase
    class << self
      # private?
      def current_session
        SessionRegistry.current_session.tap do |session|
          fail 'No session defined!' if session.nil?
        end
      end

      def current_transaction_or_session
        current_transaction || current_session
      end

      def query(*args)
        current_transaction_or_session.query(*args)
      end

      # Should support setting session via config options
      def current_session=(session)
        SessionRegistry.current_session = session
      end

      def current_adaptor=(adaptor)
        current_session = Neo4j::Core::CypherSession.new(adaptor)
      end

      def run_transaction(run_in_tx = true)
        Neo4j::Transaction.run(current_session, run_in_tx) do |tx|
          yield tx
        end
      end

      def new_transaction
        Neo4j::Transaction.new(current_session)
      end

      def new_query(options = {})
        Neo4j::Core::Query.new({session: current_session}.merge(options))
      end

      def current_transaction
        Neo4j::Transaction.current_for(current_session)
      end
    end
  end
end
