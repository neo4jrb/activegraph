require 'active_support/notifications'
require 'rails/railtie'
require 'neo4j/session_manager'
# Need the action_dispatch railtie to have action_dispatch.rescue_responses initialized correctly
require 'action_dispatch/railtie'
require 'neo4j/core/cypher_session/adaptors/http'
require 'neo4j/core/cypher_session/adaptors/bolt'
require 'neo4j/core/cypher_session/adaptors/embedded'

module Neo4j
  class Railtie < ::Rails::Railtie
    config.neo4j = ActiveSupport::OrderedOptions.new

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

    rake_tasks do
      load 'neo4j/tasks/migration.rake'
    end

    console do
      Neo4j::Config[:logger] = ActiveSupport::Logger.new(STDOUT)
    end

    # Starting Neo after :load_config_initializers allows apps to
    # register migrations in config/initializers
    initializer 'neo4j.start', after: :load_config_initializers do |app|
      neo4j_config = ActiveSupport::OrderedOptions.new
      app.config.neo4j.each { |k, v| neo4j_config[k] = v } if app.config.neo4j

      Neo4j::Config.configuration.merge!(neo4j_config.to_h)

      Neo4j::ActiveBase.on_establish_session { setup! neo4j_config }

      Neo4j::Config[:logger] ||= Rails.logger

      if Rails.env.development? && !Neo4j::Migrations.currently_running_migrations && Neo4j::Config.fail_on_pending_migrations
        Neo4j::Migrations.check_for_pending_migrations!
      end
    end

    def setup!(neo4j_config = nil)
      support_deprecated_session_configs!(neo4j_config)

      type, url, path, options, wait_for_connection = neo4j_config.session.values_at(:type, :path, :url, :options, :wait_for_connection)
      register_neo4j_cypher_logging(type || default_session_type)

      Neo4j::SessionManager.open_neo4j_session(type || default_session_type,
                                               url || path || default_session_path_or_url,
                                               wait_for_connection,
                                               options || {})
    end

    def support_deprecated_session_configs!(neo4j_config)
      ActiveSupport::Deprecation.warn('neo4j.config.sessions is deprecated, please use neo4j.config.session (not an array)') if neo4j_config.sessions.present?
      neo4j_config.session ||= (neo4j_config.sessions && neo4j_config.sessions[0]) || {}

      %w(type path url options).each do |key|
        value = neo4j_config.send("session_#{key}")
        if value.present?
          ActiveSupport::Deprecation.warn("neo4j.config.session_#{key} is deprecated, please use neo4j.config.session.#{key}")
          neo4j_config.session[key] = value
        end
      end
    end

    def default_session_type
      if ENV['NEO4J_URL']
        URI(ENV['NEO4J_URL']).scheme.tap do |scheme|
          fail "Invalid scheme for NEO4J_URL: #{scheme}" if !%w(http bolt).include?(scheme)
        end
      else
        ENV['NEO4J_TYPE'] || config_data[:type] || :http
      end.to_sym
    end

    def default_session_path_or_url
      ENV['NEO4J_URL'] || ENV['NEO4J_PATH'] ||
        config_data[:url] || config_data[:path] ||
        'http://localhost:7474'
    end


    TYPE_SUBSCRIBERS = {
      http: Neo4j::Core::CypherSession::Adaptors::HTTP.method(:subscribe_to_request),
      bolt: Neo4j::Core::CypherSession::Adaptors::Bolt.method(:subscribe_to_request),
      embedded: Neo4j::Core::CypherSession::Adaptors::Embedded.method(:subscribe_to_transaction)
    }

    def register_neo4j_cypher_logging(session_type)
      return if @neo4j_cypher_logging_registered

      Neo4j::Core::Query.pretty_cypher = Neo4j::Config[:pretty_logged_cypher_queries]

      logger_proc = ->(message) do
        (Neo4j::Config[:logger] ||= Rails.logger).debug message
      end
      Neo4j::Core::CypherSession::Adaptors::Base.subscribe_to_query(&logger_proc)
      TYPE_SUBSCRIBERS[session_type.to_sym].call(&logger_proc)

      @neo4j_cypher_logging_registered = true
    end
  end
end
