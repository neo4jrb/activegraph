require 'active_support/core_ext/hash'
require 'active_support/ordered_options'
require 'neo4j/core/cypher_session/adaptors/http'
require 'neo4j/core/cypher_session/adaptors/bolt'
require 'neo4j/core/cypher_session/adaptors/embedded'

module Neo4j
  class SessionManager
    class << self
      def open_neo4j_session(type, url_or_path, wait_for_connection = false, options = {})
        enable_unlimited_strength_crypto! if java_platform? && session_type_is_embedded?(type)

        adaptor = wait_for_value(wait_for_connection, Neo4j::Core::CypherSession::ConnectionFailedError) do
          cypher_session_adaptor(type, url_or_path, options.merge(wrap_level: :proc))
        end

        Neo4j::Core::CypherSession.new(adaptor)
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

      # TODO: Deprecate embedded_db and http in favor of embedded and http
      #
      def cypher_session_adaptor(type, path_or_url, options = {})
        case type.to_sym
        when :embedded_db, :embedded
          Neo4j::Core::CypherSession::Adaptors::Embedded.new(path_or_url, options)
        when :http
          Neo4j::Core::CypherSession::Adaptors::HTTP.new(path_or_url, options)
        when :bolt
          Neo4j::Core::CypherSession::Adaptors::Bolt.new(path_or_url, options)
        else
          extra = ' (`server_db` has been replaced by `http` or `bolt`)'
          fail ArgumentError, "Invalid session type: #{type.inspect}#{extra if type.to_sym == :server_db}"
        end
      end

      def java_platform?
        RUBY_PLATFORM =~ /java/
      end

      def wait_for_value(wait, exception_class)
        value = nil
        Timeout.timeout(60) do
          until value
            begin
              if value = yield
                # puts
                return value
              end
            rescue exception_class => e
              raise e if !wait

              # putc '.'
              sleep(1)
            end
          end
        end
      end
    end
  end
end
