module Neo4j
  module Rails
    class LuceneConnectionCloser
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      ensure
        Thread.current[:neo4j_lucene_connection].each {|hits| hits.close} if Thread.current[:neo4j_lucene_connection]
        Thread.current[:neo4j_lucene_connection] = nil
      end
    end
  end

end

Thread.current