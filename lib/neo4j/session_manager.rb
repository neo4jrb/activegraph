require 'active_support/core_ext/hash'
require 'active_support/ordered_options'
require 'neo4j/core/cypher_session/adaptors/http'
require 'neo4j/core/cypher_session/adaptors/bolt'
require 'neo4j/core/cypher_session/adaptors/embedded'

module Neo4j
  class SessionManager
    class << self
      def open_neo4j_session(type, url_or_path, url, wait_for_connection = false, options = {})
        enable_unlimited_strength_crypto! if java_platform? && session_type_is_embedded?(session_type)

        adaptor = wait_for_value(wait_for_connection) do
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

      def config_data
        @config_data ||= if yaml_path
                           HashWithIndifferentAccess.new(YAML.load(ERB.new(yaml_path.read).result)[Rails.env])
                         else
                           {}
                         end
      end

      def yaml_path
        return unless defined?(Rails)
        @yaml_path ||= %w(config/neo4j.yml config/neo4j.yaml).map do |path|
          Rails.root.join(path)
        end.detect(&:exist?)
      end

      # TODO: Deprecate embedded_db and http in favor of embedded and http
      #
      def cypher_session_adaptor(type, path_or_url, options = {})
        case type
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

      def wait_for_value(wait)
        session = nil
        Timeout.timeout(60) do
          until session
            begin
              if session = yield
                puts
                return session
              end
            rescue Neo4j::Core::CypherSession::ConnectionFailedError
              raise e if !wait

              putc '.'
              sleep(1)
            end
          end
        end
      end
    end
  end
end
