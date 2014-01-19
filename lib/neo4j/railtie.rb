module Neo4j
  class Railtie < ::Rails::Railtie
    config.neo4j = ActiveSupport::OrderedOptions.new

    # Add ActiveModel translations to the I18n load_path
    initializer "i18n" do |app|
    	config.i18n.load_path += Dir[File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'locales', '*.{rb,yml}')]
    end

    # Starting Neo after :load_config_initializers allows apps to
    # register migrations in config/initializers
    initializer "neo4j.start", :after => :load_config_initializers do |app|
      cfg = app.config.neo4j
      # Set Rails specific defaults

      cfg.session_type ||= :server_db
      cfg.session_path ||= "http://localhost:7474"
      cfg.sessions ||= []

      if cfg.sessions.empty?
        cfg.sessions << {type: cfg.session_type, path: cfg.session_path}
      end

      cfg.sessions.each do |session_opts|
        if !(RUBY_PLATFORM =~ /java/) && session_opts[:type] == :embedded_db
          raise "Tried to start embedded Neo4j db without using JRuby (got #{RUBY_PLATFORM}), please run `rvm jruby`"
        end

        puts "Create Neo4j Session #{session_opts[:type]}, path: #{session_opts[:path]}"
        if (session_opts.key? :name)
          session = Neo4j::Session.open_named(session_opts[:type], session_opts[:name], session_opts[:default], session_opts[:path])
        else
          session = Neo4j::Session.open(session_opts[:type], session_opts[:path])
        end

        if session_opts[:type] == :embedded_db

          # See https://github.com/jruby/jruby/wiki/UnlimitedStrengthCrypto
          security_class = java.lang.Class.for_name('javax.crypto.JceSecurity')
          restricted_field = security_class.get_declared_field('isRestricted')
          restricted_field.accessible = true
          restricted_field.set nil, false

          session.start
        end
      end

      #cfg.storage_path = "#{app.config.root}/db/neo4j-#{::Rails.env}" unless cfg.storage_path
      #Neo4j::Config.setup.merge!(cfg.to_hash)
    end
  end
end
