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

    console do |app|
      Neo4j::Config[:logger] = ActiveSupport::Logger.new(STDOUT)

      register_neo4j_cypher_logging(app.config.neo4j.sessions.map { |s| s[:type] })
    end

    # Starting Neo after :load_config_initializers allows apps to
    # register migrations in config/initializers
    initializer 'neo4j.start', after: :load_config_initializers do |app|
      cfg = app.config.neo4j
      # Set Rails specific defaults
      Neo4j::SessionManager.setup! cfg

      Neo4j::Config[:logger] ||= Rails.logger

      session_types = cfg.sessions.map { |session_opts| session_opts[:type] }

      register_neo4j_cypher_logging(session_types)
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
  end
end
