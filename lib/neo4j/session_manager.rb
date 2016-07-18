require 'active_support/core_ext/hash'
require 'active_support/ordered_options'

module Neo4j
  class SessionManager
    class << self
      def setup!(cfg = nil)
        cfg ||= ActiveSupport::OrderedOptions.new

        setup_default_session(cfg)

        cfg.sessions.each do |session_opts|
          open_neo4j_session(session_opts, cfg.wait_for_connection)
        end
        Neo4j::Config.configuration.merge!(cfg.to_hash)
      end

      def setup_default_session(cfg)
        setup_config_defaults!(cfg)

        return if !cfg.sessions.empty?

        cfg.sessions << {type: cfg.session_type, path: cfg.session_path, options: cfg.session_options.merge(default: true)}
      end

      def setup_config_defaults!(cfg)
        cfg.session_type ||= default_session_type
        cfg.session_path ||= default_session_path
        cfg.session_options ||= {}
        cfg.sessions ||= []
      end

      def start_embedded_session(session)
        # See https://github.com/jruby/jruby/wiki/UnlimitedStrengthCrypto
        security_class = java.lang.Class.for_name('javax.crypto.JceSecurity')
        restricted_field = security_class.get_declared_field('isRestricted')
        restricted_field.accessible = true
        restricted_field.set nil, false
        session.start
      end

      def open_neo4j_session(options, wait_for_connection = false)
        type, name, default, path = options.values_at(:type, :name, :default, :path)

        if !java_platform? && type == :embedded_db
          fail "Tried to start embedded Neo4j db without using JRuby (got #{RUBY_PLATFORM}), please run `rvm jruby`"
        end

        session = wait_for_value(wait_for_connection) do
          if options.key?(:name)
            Neo4j::Session.open_named(type, name, default, path)
          else
            Neo4j::Session.open(type, path, options[:options])
          end
        end

        start_embedded_session(session) if type == :embedded_db
      end

      protected

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

      def default_session_type
        type = ENV['NEO4J_TYPE'] || config_data[:type] || :server_db
        type.to_sym
      end

      def default_session_path
        ENV['NEO4J_URL'] || ENV['NEO4J_PATH'] ||
          config_data[:url] || config_data[:path] ||
          'http://localhost:7474'
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
            rescue Faraday::ConnectionFailed => e
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
