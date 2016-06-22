module Neo4j
  module Migrations
    extend ActiveSupport::Autoload
    autoload :Helpers
    autoload :MigrationFile
    autoload :Base
    autoload :Runner
    autoload :SchemaMigration
  end
end
