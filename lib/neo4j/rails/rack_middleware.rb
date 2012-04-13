module Neo4j
  module Rails
    # close lucene connections
    # reset the Neo4j.threadlocal_ref_node (Multitenancy)
    # clear the identity map
    class Middleware
      class Body #:nodoc:
        def initialize(target, original)
          @target = target
          @original = original
        end

        def each(&block)
          @target.each(&block)
        end

        def close
          @target.close if @target.respond_to?(:close)
        ensure
          IdentityMap.enabled = @original
          IdentityMap.clear
        end
      end

      def initialize(app)
        @app = app
      end

      def call(env)
        enabled = IdentityMap.enabled
        IdentityMap.enabled = Neo4j::Config[:identity_map]
        status, headers, body = @app.call(env)
        [status, headers, Body.new(body, enabled)]
      ensure
        Neo4j::RailsNode.close_lucene_connections
        Neo4j.threadlocal_ref_node = Neo4j.default_ref_node
      end
    end

  end


end
