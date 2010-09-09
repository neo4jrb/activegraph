module Neo4j
  module Rails
    class TransactionManagement
      def initialize(app)
        @app = app
      end

      def call(env)
        Neo4j::Transaction.new
        @app.call(env)
      rescue
        Neo4j::Transaction.failure
        raise
      ensure
        Neo4j::Transaction.finish
      end
    end
  end

end