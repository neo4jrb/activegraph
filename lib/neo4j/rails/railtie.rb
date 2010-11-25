module Neo4j
  class Railtie < ::Rails::Railtie
    config.neo4j = ActiveSupport::OrderedOptions.new

    initializer "neo4j.tx" do |app|
      app.config.middleware.use Neo4j::Rails::LuceneConnectionCloser
    end
    
    # Add ActiveModel translations to the I18n load_path
    initializer "i18n" do |app|
    	config.i18n.load_path += Dir[File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'locales', '*.{rb,yml}')]
    end

    # Starting Neo after :load_config_initializers allows apps to
    # register migrations in config/initializers
    initializer "neo4j.start", :after => :load_config_initializers do |app|
      Neo4j::Config.setup.merge!(app.config.neo4j.to_hash)
    end
  end
end
