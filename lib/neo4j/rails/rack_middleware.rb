module Neo4j
  module Rails
    # close lucene connections
    # reset the Neo4j.threadlocal_ref_node (Multitenancy)
    class RackMiddleware  #:nodoc:
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      ensure
        Neo4j::Rails::Model.close_lucene_connections
        Neo4j.threadlocal_ref_node = Neo4j.default_ref_node
      end
    end
  end

end
