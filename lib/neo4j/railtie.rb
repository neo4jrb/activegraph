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

      if !(RUBY_PLATFORM =~ /java/) && cfg.session_type == :embedded_db
        raise "Tried to start embedded Neo4j db without using JRuby (got #{RUBY_PLATFORM}), please run `rvm jruby`"
      end

      puts "Create Neo4j Session #{cfg.session_type}, path: #{cfg.session_path}"
      session = Neo4j::Session.open(cfg.session_type, cfg.session_path)
      if cfg.session_type == :embedded_db

        # See https://github.com/jruby/jruby/wiki/UnlimitedStrengthCrypto
        security_class = java.lang.Class.for_name('javax.crypto.JceSecurity')
        restricted_field = security_class.get_declared_field('isRestricted')
        restricted_field.accessible = true
        restricted_field.set nil, false

        session.start
      end

      #cfg.storage_path = "#{app.config.root}/db/neo4j-#{::Rails.env}" unless cfg.storage_path
      #Neo4j::Config.setup.merge!(cfg.to_hash)
    end
  end
end
