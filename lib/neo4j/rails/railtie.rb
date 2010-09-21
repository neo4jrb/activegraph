module Neo4j
  class Railtie < ::Rails::Railtie
    config.neo4j = ActiveSupport::OrderedOptions.new

    initializer "neo4j.tx" do |app|
      app.config.middleware.use Neo4j::Rails::LuceneConnectionCloser
    end

    # Starting Neo after :load_config_initializers allows apps to
    # register migrations in config/initializers
    initializer "neo4j.start", :after => :load_config_initializers do |app|
      Neo4j::Config.setup.merge!(app.config.neo4j.to_hash)
      Neo4j.start
    end
  end
end
