module Neo4j
  module Rails
    class LuceneConnectionCloser
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      ensure
        Neo4j::Rails::Model.close_lucene_connections
      end
    end
  end

end

Thread.current