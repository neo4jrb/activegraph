require 'active_support/notifications'
require 'rails/railtie'
require 'neo4j/session_manager'
# Need the action_dispatch railtie to have action_dispatch.rescue_responses initialized correctly
require 'action_dispatch/railtie'
require 'neo4j/core/cypher_session/adaptors'

module Neo4j
  class Railtie < ::Rails::Railtie
    def empty_config
      ActiveSupport::OrderedOptions.new.tap { |cfg| cfg.session = ActiveSupport::OrderedOptions.new }
    end

    config.neo4j = empty_config

    if defined?(ActiveSupport::Reloader)
      ActiveSupport::Reloader.to_prepare do
        Neo4j::ActiveNode::Labels::Reloading.reload_models!
      end
    elsif const_defined?(:ActionDispatch)
      ActionDispatch::Reloader.to_prepare do
        Neo4j::ActiveNode::Labels::Reloading.reload_models!
      end
    end

    # Rescue responses similar to ActiveRecord.
    config.action_dispatch.rescue_responses.merge!(
      'Neo4j::RecordNotFound' => :not_found,
      'Neo4j::ActiveNode::Labels::RecordNotFound' => :not_found
    )

    # Add ActiveModel translations to the I18n load_path
    initializer 'i18n' do
      config.i18n.load_path += Dir[File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'locales', '*.{rb,yml}')]
    end

    console do
      Neo4j::Config[:logger] = ActiveSupport::Logger.new(STDOUT)
      Neo4j::Config[:verbose_query_logs] = false
    end

    # Starting Neo after :load_config_initializers allows apps to
    # register migrations in config/initializers
    initializer 'neo4j.start', after: :load_config_initializers do |app|
      app.config.neo4j.skip_migration_check = true if Rails.env.test?

      neo4j_config = ActiveSupport::OrderedOptions.new
      app.config.neo4j.each { |k, v| neo4j_config[k] = v } if app.config.neo4j

      Neo4j::Config.configuration.merge!(neo4j_config.to_h)

      Neo4j::ActiveBase.on_establish_session { setup! neo4j_config }

      Neo4j::Config[:logger] ||= Rails.logger

      if Neo4j::Config.fail_on_pending_migrations
        config.app_middleware.insert_after ::ActionDispatch::Callbacks, Neo4j::Migrations::CheckPending
      end
    end

    def setup!(neo4j_config = empty_config)
      wait_for_connection = neo4j_config.wait_for_connection
      type, url, path, options = final_session_config!(neo4j_config).values_at(:type, :url, :path, :options)
      type ||= default_session_type
      options ||= {}
      register_neo4j_cypher_logging(type, options)

      Neo4j::SessionManager.open_neo4j_session(type,
                                               url || path || default_session_path_or_url,
                                               wait_for_connection,
                                               options)
    end

    def final_session_config!(neo4j_config)
      support_deprecated_session_configs!(neo4j_config)

      (neo4j_config[:session].empty? ? yaml_config_data : neo4j_config[:session]).dup.tap do |result|
        result[:type] ||= URI(result[:url]).scheme if result[:url]
      end
    end

    def support_deprecated_session_configs!(neo4j_config)
      if neo4j_config.sessions.present?
        ActiveSupport::Deprecation.warn('neo4j.config.sessions is deprecated, please use neo4j.config.session (not an array)')
        neo4j_config[:session] = neo4j_config.sessions[0] if neo4j_config[:session].empty?
      end

      %w(type path url options).each do |key|
        value = neo4j_config.send("session_#{key}")
        if value.present?
          ActiveSupport::Deprecation.warn("neo4j.config.session_#{key} is deprecated, please use neo4j.config.session.#{key}")
          neo4j_config[:session][key] = value
        end
      end
    end

    def default_session_type
      if ENV['NEO4J_URL']
        scheme = URI(ENV['NEO4J_URL']).scheme
        fail "Invalid scheme for NEO4J_URL: #{scheme}" if !%w(http https bolt).include?(scheme)
        scheme == 'https' ? 'http' : scheme
      else
        ENV['NEO4J_TYPE'] || :http
      end.to_sym
    end

    def default_session_path_or_url
      ENV['NEO4J_URL'] || ENV['NEO4J_PATH'] || 'http://localhost:7474'
    end

    def yaml_config_data
      @yaml_config_data ||= if yaml_path
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

    def register_neo4j_cypher_logging(session_type, options)
      return if @neo4j_cypher_logging_registered

      Neo4j::Core::Query.pretty_cypher = Neo4j::Config[:pretty_logged_cypher_queries]

      logger_proc = ->(message) do
        (Neo4j::Config[:logger] ||= Rails.logger).debug message
      end
      Neo4j::Core::CypherSession::Adaptors::Base.subscribe_to_query(&logger_proc)
      subscribe_to_session_type_logging!(session_type, options, logger_proc)

      @neo4j_cypher_logging_registered = true
    end

    def subscribe_to_session_type_logging!(session_type, options, logger_proc)
      SessionManager
        .adaptor_class(session_type, options)
        .send(
          [:embedded, :embedded_db].include?(session_type.to_sym) ? :subscribe_to_transaction : :subscribe_to_request,
          &logger_proc
        )
    end
  end
end
