require File.expand_path('../boot', __FILE__)

require 'rails'

%w(
  neo4j
  action_controller
  action_mailer
  sprockets
).each do |framework|
  begin
    require "#{framework}/railtie"
  rescue LoadError
  end
end


# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Blog
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # config.neo4j.session_type = :embedded_db
    # config.neo4j.session_path = File.expand_path('neo4j-db', Rails.root)

    # Example of using UUID instead of Neo4j's id (neo_id)
    # config.neo4j.id_property = :uuid
    # config.neo4j.id_property_type = :auto
    # config.neo4j.id_property_type_value = :uuid

  end
end
