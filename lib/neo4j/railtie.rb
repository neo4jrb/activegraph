module Neo4j
    class Railtie < ::Rails::Railtie
    config.neo4j = ActiveSupport::OrderedOptions.new

    # Add ActiveModel translations to the I18n load_path
    initializer "i18n" do |app|
    	config.i18n.load_path += Dir[File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'locales', '*.{rb,yml}')]
    end

    class << self
      def java_platform?
        RUBY_PLATFORM =~ /java/
      end

      def set_default_session(cfg)
        cfg.session_type ||= :server_db
        cfg.session_path ||= "http://localhost:7474"
        cfg.session_options ||= {}
        cfg.sessions ||= []

        unless (uri = URI(cfg.session_path)).user.blank?
          cfg.session_options.reverse_merge!({ basic_auth: { username: uri.user, password: uri.password } })
          cfg.session_path = cfg.session_path.gsub("#{uri.user}:#{uri.password}@", '')
        end

        if cfg.sessions.empty?
          cfg.sessions << {type: cfg.session_type, path: cfg.session_path, options: cfg.session_options}
        end
      end


      def start_embedded_session(session)
        # See https://github.com/jruby/jruby/wiki/UnlimitedStrengthCrypto
        security_class = java.lang.Class.for_name('javax.crypto.JceSecurity')
        restricted_field = security_class.get_declared_field('isRestricted')
        restricted_field.accessible = true
        restricted_field.set nil, false
        session.start
      end

      def open_neo4j_session(session_opts)
        if !java_platform? && session_opts[:type] == :embedded_db
          raise "Tried to start embedded Neo4j db without using JRuby (got #{RUBY_PLATFORM}), please run `rvm jruby`"
        end

        if (session_opts.key? :name)
          session = Neo4j::Session.open_named(session_opts[:type], session_opts[:name], session_opts[:default], session_opts[:path])
        else
          session = Neo4j::Session.open(session_opts[:type], session_opts[:path], session_opts[:options])
        end

        start_embedded_session(session) if session_opts[:type] == :embedded_db
      end

    end


    # Starting Neo after :load_config_initializers allows apps to
    # register migrations in config/initializers
    initializer "neo4j.start", :after => :load_config_initializers do |app|
      cfg = app.config.neo4j
      # Set Rails specific defaults
      Neo4j::Railtie.set_default_session(cfg)

      cfg.sessions.each do |session_opts|
        Neo4j::Railtie.open_neo4j_session(session_opts)
      end
    end
  end
end
