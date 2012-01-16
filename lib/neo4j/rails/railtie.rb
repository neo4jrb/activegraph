module Neo4j
  class Railtie < ::Rails::Railtie
    config.neo4j = ActiveSupport::OrderedOptions.new

    initializer "neo4j.tx" do |app|
      app.config.middleware.use Neo4j::Rails::RackMiddleware
      app.config.middleware.use Neo4j::IdentityMap::Middleware
    end

    # Add ActiveModel translations to the I18n load_path
    initializer "i18n" do |app|
    	config.i18n.load_path += Dir[File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'locales', '*.{rb,yml}')]
    end

    # Starting Neo after :load_config_initializers allows apps to
    # register migrations in config/initializers
    initializer "neo4j.start", :after => :load_config_initializers do |app|
      cfg = app.config.neo4j
      # Set Rails specific defaults
      cfg.storage_path = "#{app.config.root}/db/neo4j-#{::Rails.env}" unless cfg.storage_path
      Neo4j::Config.setup.merge!(cfg.to_hash)
    end

    # Instantitate any registered observers after Rails initialization and
    # instantiate them after being reloaded in the development environment
    initializer "instantiate.observers" do
      config.after_initialize do
        ::Neo4j::Rails::Model.observers = config.neo4j.observers || []
        ::Neo4j::Rails::Model.instantiate_observers

        ActionDispatch::Callbacks.to_prepare do
          ::Neo4j::Rails::Model.instantiate_observers
        end
      end
    end
  end
end
