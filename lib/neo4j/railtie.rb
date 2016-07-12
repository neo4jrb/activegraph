require 'active_support/notifications'
require 'rails/railtie'
# Need the action_dispatch railtie to have action_dispatch.rescue_responses initialized correctly
require 'action_dispatch/railtie'
require 'neo4j/core/cypher_session/adaptors/http'
require 'neo4j/core/cypher_session/adaptors/bolt'
require 'neo4j/core/cypher_session/adaptors/embedded'

module Neo4j
  class Railtie < ::Rails::Railtie
    config.neo4j = ActiveSupport::OrderedOptions.new

    if const_defined?(:ActionDispatch)
      ActionDispatch::Reloader.to_prepare do
        Neo4j::ActiveNode::Labels::Reloading.reload_models!
      end
    end

    # Rescue responses similar to ActiveRecord.
    # For rails 3.2 and 4.0
    if config.action_dispatch.respond_to?(:rescue_responses)
      config.action_dispatch.rescue_responses.merge!(
        'Neo4j::RecordNotFound' => :not_found,
        'Neo4j::ActiveNode::Labels::RecordNotFound' => :not_found
      )
    else
      # For rails 3.0 and 3.1
      ActionDispatch::ShowExceptions.rescue_responses['Neo4j::RecordNotFound'] = :not_found
      ActionDispatch::ShowExceptions.rescue_responses['Neo4j::ActiveNode::Labels::RecordNotFound'] = :not_found
    end

    # Add ActiveModel translations to the I18n load_path
    initializer 'i18n' do
      config.i18n.load_path += Dir[File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'locales', '*.{rb,yml}')]
    end

    rake_tasks do
      load 'neo4j/tasks/migration.rake'
    end

    class << self
      # TODO: Remove ability for multiple sessions?
      # Ability to overwrite default session per-model like ActiveRecord?
      def setup_default_session!(cfg)
        setup_config_defaults!(cfg)

        return if !cfg.sessions.empty?

        cfg.sessions << {type: cfg.session_type, path: cfg.session_path, options: cfg.session_options.merge(default: true)}
      end

      # TODO: Support `session_url` config for server mode
      def setup_config_defaults!(cfg)
        cfg.session_type ||= default_session_type
        cfg.session_path ||= default_session_path
        cfg.session_options ||= {}
        cfg.sessions ||= []
      end

      def config_data
        @config_data ||= if yaml_path
                           HashWithIndifferentAccess.new(YAML.load(ERB.new(yaml_path.read).result)[Rails.env])
                         else
                           {}
                         end
      end

      def yaml_path
        @yaml_path ||= %w(config/neo4j.yml config/neo4j.yaml).map do |path|
          Rails.root.join(path)
        end.detect(&:exist?)
      end

      def default_session_type
        if ENV['NEO4J_TYPE']
          :embedded
        else
          config_data[:type] || :http
        end.to_sym
      end

      def default_session_path
        ENV['NEO4J_URL'] || ENV['NEO4J_PATH'] ||
          config_data[:url] || config_data[:path] ||
          'http://localhost:7474'
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
        case type
        when :embedded_db, :embedded
          require 'neo4j/core/cypher_session/adaptors/embedded'
          Neo4j::Core::CypherSession::Adaptors::Embedded.new(path_or_url, options)
        when :http
          require 'neo4j/core/cypher_session/adaptors/http'
          Neo4j::Core::CypherSession::Adaptors::HTTP.new(path_or_url, options)
        else
          extra = ' (`server_db` has been replaced by `http` or `bolt`)'
          fail ArgumentError, "Invalid session type: #{type.inspect} #{extra if type.to_sym == :server_db}"
        end
      end

      def session_type_is_embedded?(session_type)
        [:embedded_db, :embedded].include?(session_type)
      end

      def validate_platform!(session_type)
        return if !RUBY_PLATFORM =~ /java/
        return if !session_type_is_embedded?(session_type)

        fail ArgumentError, 'server_db is no longer supported.  Use `http` instead for HTTP JSON connections' if session_type == :server_db

        fail ArgumentError, "Tried to start embedded Neo4j db without using JRuby (got #{RUBY_PLATFORM}), please run `rvm jruby`"
      end

      def open_neo4j_session(options, wait_for_connection = false)
        session_type, path, url = options.values_at(:type, :path, :url)

        validate_platform!(session_type)
        enable_unlimited_strength_crypto! if session_type_is_embedded?(session_type)

        adaptor = wait_for_value(wait_for_connection) do
          cypher_session_adaptor(session_type, url || path, (options[:options] || {}).merge(wrap_level: :proc))
        end

        Neo4j::ActiveBase.current_adaptor = adaptor
      end
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

    TYPE_SUBSCRIBERS = {
      http: Neo4j::Core::CypherSession::Adaptors::HTTP.method(:subscribe_to_request),
      bolt: Neo4j::Core::CypherSession::Adaptors::Bolt.method(:subscribe_to_request),
      embedded: Neo4j::Core::CypherSession::Adaptors::Embedded.method(:subscribe_to_transaction)
    }
    def register_neo4j_cypher_logging(session_types)
      return if @neo4j_cypher_logging_registered

      Neo4j::Core::Query.pretty_cypher = Neo4j::Config[:pretty_logged_cypher_queries]

      logger_proc = ->(message) do
        (Neo4j::Config[:logger] ||= Rails.logger).debug message
      end
      Neo4j::Core::CypherSession::Adaptors::Base.subscribe_to_query(&logger_proc)
      session_types.map(&:to_sym).uniq.each do |type|
        TYPE_SUBSCRIBERS[type].call(&logger_proc)
      end

      @neo4j_cypher_logging_registered = true
    end

    console do |app|
      Neo4j::Config[:logger] = ActiveSupport::Logger.new(STDOUT)

      register_neo4j_cypher_logging(app.config.neo4j.sessions.map { |s| s[:type] })
    end

    # Starting Neo after :load_config_initializers allows apps to
    # register migrations in config/initializers
    initializer 'neo4j.start', after: :load_config_initializers do |app|
      cfg = app.config.neo4j
      # Set Rails specific defaults
      Neo4j::Railtie.setup_default_session!(cfg)

      session_types = []
      cfg.sessions.each do |session_opts|
        session_types << session_opts[:type]
        Neo4j::Railtie.open_neo4j_session(session_opts, cfg.wait_for_connection)
      end
      Neo4j::Config.configuration.merge!(cfg.to_hash)

      Neo4j::Config[:logger] ||= Rails.logger

      register_neo4j_cypher_logging(session_types)
    end
  end
end
