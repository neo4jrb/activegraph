require 'active_support/notifications'
require 'rails/railtie'

module Neo4j
  class Railtie < ::Rails::Railtie
    config.neo4j = ActiveSupport::OrderedOptions.new

    if const_defined?(:ActionDispatch)
      ActionDispatch::Reloader.to_prepare do
        Neo4j::ActiveNode::Labels::Reloading.reload_models!
      end
    end

    # Add ActiveModel translations to the I18n load_path
    initializer 'i18n' do
      config.i18n.load_path += Dir[File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'locales', '*.{rb,yml}')]
    end

    rake_tasks do
      load 'neo4j/tasks/migration.rake'
    end

    class << self
      def java_platform?
        RUBY_PLATFORM =~ /java/
      end

      def setup_default_session(cfg)
        setup_config_defaults!(cfg)

        return if !cfg.sessions.empty?

        cfg.sessions << {type: cfg.session_type, path: cfg.session_path, options: cfg.session_options}
      end

      def setup_config_defaults!(cfg)
        cfg.session_type ||= :server_db
        cfg.session_path ||= 'http://localhost:7474'
        cfg.session_options ||= {}
        cfg.sessions ||= []

        uri = URI(cfg.session_path)
        return if uri.user.blank?

        cfg.session_options.reverse_merge!(basic_auth: {username: uri.user, password: uri.password})
        cfg.session_path = cfg.session_path.gsub("#{uri.user}:#{uri.password}@", '')
      end


      def start_embedded_session(session)
        # See https://github.com/jruby/jruby/wiki/UnlimitedStrengthCrypto
        security_class = java.lang.Class.for_name('javax.crypto.JceSecurity')
        restricted_field = security_class.get_declared_field('isRestricted')
        restricted_field.accessible = true
        restricted_field.set nil, false
        session.start
      end

      def open_neo4j_session(options)
        type, name, default, path = options.values_at(:type, :name, :default, :path)

        if !java_platform? && type == :embedded_db
          fail "Tried to start embedded Neo4j db without using JRuby (got #{RUBY_PLATFORM}), please run `rvm jruby`"
        end

        session = if options.key?(:name)
                    Neo4j::Session.open_named(type, name, default, path)
                  else
                    Neo4j::Session.open(type, path, options[:options])
                  end

        start_embedded_session(session) if type == :embedded_db
      end
    end

    def register_neo4j_cypher_logging
      return if @neo4j_cypher_logging_registered

      Neo4j::Core::Query.pretty_cypher = Neo4j::Config[:pretty_logged_cypher_queries]

      Neo4j::Server::CypherSession.log_with do |message|
        (Neo4j::Config[:logger] || Rails.logger).debug message
      end

      @neo4j_cypher_logging_registered = true
    end

    console do
      Neo4j::Config[:logger] = ActiveSupport::Logger.new(STDOUT)

      register_neo4j_cypher_logging
    end

    # Starting Neo after :load_config_initializers allows apps to
    # register migrations in config/initializers
    initializer 'neo4j.start', after: :load_config_initializers do |app|
      cfg = app.config.neo4j
      # Set Rails specific defaults
      Neo4j::Railtie.setup_default_session(cfg)

      cfg.sessions.each do |session_opts|
        Neo4j::Railtie.open_neo4j_session(session_opts)
      end
      Neo4j::Config.configuration.merge!(cfg.to_hash)

      Neo4j::Config[:logger] ||= Rails.logger

      register_neo4j_cypher_logging
    end
  end
end
