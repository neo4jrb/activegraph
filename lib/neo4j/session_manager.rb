require 'active_support/core_ext/hash'
require 'active_support/ordered_options'

module Neo4j
  class SessionManager
    class << self
      def open_neo4j_session(type, url_or_path, wait_for_connection = false, options = {})
        enable_unlimited_strength_crypto! if java_platform? && session_type_is_embedded?(type)

        verbose_query_logs = Neo4j::Config.fetch(:verbose_query_logs, false)
        adaptor = cypher_session_adaptor(type, url_or_path, options.merge(wrap_level: :proc,
                                                                          verbose_query_logs: verbose_query_logs))
        session = Neo4j::Core::CypherSession.new(adaptor)
        wait_and_retry(session) if wait_for_connection
        session
      end

      def adaptor_class(type, options)
        options[:adaptor_class] || adaptor_class_by_type(type.to_sym)
      end

      protected

      def session_type_is_embedded?(session_type)
        [:embedded_db, :embedded].include?(session_type)
      end

      def enable_unlimited_strength_crypto!
        # See https://github.com/jruby/jruby/wiki/UnlimitedStrengthCrypto
        security_class = java.lang.Class.for_name('javax.crypto.JceSecurity')
        restricted_field = security_class.get_declared_field('isRestricted')
        restricted_field.accessible = true
        restricted_field.set nil, false
      end

      def cypher_session_adaptor(type, path_or_url, options = {})
        adaptor_class(type, options).new(path_or_url, options)
      end

      def java_platform?
        RUBY_PLATFORM =~ /java/
      end

      def wait_and_retry(session)
        Timeout.timeout(60) do
          begin
            session.constraints
          rescue Neo4j::Core::CypherSession::ConnectionFailedError
            sleep(1)
            retry
          end
        end
      rescue Timeout::Error
        raise Timeout::Error, 'Timeout while waiting for connection to neo4j database'
      end

      private

      def adaptor_class_by_type(type)
        ActiveSupport::Deprecation.warn('`embedded_db` session type is deprecated, please use `embedded`') if type == :embedded_db
        case type
        when :embedded_db, :embedded
          require 'neo4j/core/cypher_session/adaptors/embedded'
          Neo4j::Core::CypherSession::Adaptors::Embedded
        when :http
          require 'neo4j/core/cypher_session/adaptors/http'
          Neo4j::Core::CypherSession::Adaptors::HTTP
        when :bolt
          require 'neo4j/core/cypher_session/adaptors/bolt'
          Neo4j::Core::CypherSession::Adaptors::Bolt
        else
          extra = ' (`server_db` has been replaced by `http` or `bolt`)'
          fail ArgumentError, "Invalid session type: #{type.inspect} (expected one of [:http, :bolt, :embedded])#{extra if type == :server_db}"
        end
      end
    end
  end
end
