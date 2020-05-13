require 'active_support/notifications'
require 'rails/railtie'
# Need the action_dispatch railtie to have action_dispatch.rescue_responses initialized correctly
require 'action_dispatch/railtie'

module ActiveGraph
  class Railtie < ::Rails::Railtie
    def empty_config
      ActiveSupport::OrderedOptions.new.tap do |cfg|
        cfg.driver = ActiveSupport::OrderedOptions.new.tap { |cfg| cfg.config = ActiveSupport::OrderedOptions.new }
      end
    end

    config.neo4j = empty_config

    if defined?(ActiveSupport::Reloader)
      ActiveSupport::Reloader.to_prepare do
        ActiveGraph::Node::Labels::Reloading.reload_models!
      end
    elsif const_defined?(:ActionDispatch)
      ActionDispatch::Reloader.to_prepare do
        ActiveGraph::Node::Labels::Reloading.reload_models!
      end
    end

    # Rescue responses similar to ActiveRecord.
    config.action_dispatch.rescue_responses.merge!(
      'ActiveGraph::RecordNotFound' => :not_found,
      'ActiveGraph::Node::Labels::RecordNotFound' => :not_found
    )

    # Add ActiveModel translations to the I18n load_path
    initializer 'i18n' do
      config.i18n.load_path += Dir[File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'locales', '*.{rb,yml}')]
    end

    console do
      ActiveGraph::Config[:logger] = ActiveSupport::Logger.new(STDOUT)
      ActiveGraph::Config[:verbose_query_logs] = false
    end

    # Starting Neo after :load_config_initializers allows apps to
    # register migrations in config/initializers
    initializer 'neo4j.start', after: :load_config_initializers do |app|
      app.config.neo4j.skip_migration_check = true if Rails.env.test?

      neo4j_config = ActiveSupport::OrderedOptions.new
      app.config.neo4j.each { |k, v| neo4j_config[k] = v } if app.config.neo4j

      ActiveGraph::Config.configuration.merge!(neo4j_config.to_h)

      ActiveGraph::Base.on_establish_driver { setup! neo4j_config }

      ActiveGraph::Config[:logger] ||= Rails.logger

      if ActiveGraph::Config.fail_on_pending_migrations
        config.app_middleware.insert_after ::ActionDispatch::Callbacks, ActiveGraph::Migrations::CheckPending
      end
    end

    def setup!(neo4j_config = empty_config)
      url, path, auth_token, username, password, config =
        final_driver_config!(neo4j_config).values_at(:url, :path, :auth_token, :username, :password, :config)
      auth_token ||= username ? Neo4j::Driver::AuthTokens.basic(username, password) : Neo4j::Driver::AuthTokens.none
      register_neo4j_cypher_logging

      url ||= path || default_driver_path_or_url
      method = url.is_a?(Enumerable) ? :routing_driver : :driver
      Neo4j::Driver::GraphDatabase.send(method, url, auth_token, config)
    end

    def final_driver_config!(neo4j_config)
      (neo4j_config[:driver].empty? ? yaml_config_data : neo4j_config[:driver]).dup
    end

    def default_driver_path_or_url
      ENV['NEO4J_URL'] || ENV['NEO4J_PATH'] || 'bolt://localhost:7474'
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

    def register_neo4j_cypher_logging
      return if @neo4j_cypher_logging_registered

      ActiveGraph::Core::Query.pretty_cypher = ActiveGraph::Config[:pretty_logged_cypher_queries]

      logger_proc = ->(message) do
        (ActiveGraph::Config[:logger] ||= Rails.logger).debug message
      end
      ActiveGraph::Base.subscribe_to_query(&logger_proc)
      ActiveGraph::Base.subscribe_to_request(&logger_proc)

      @neo4j_cypher_logging_registered = true
    end
  end
end
