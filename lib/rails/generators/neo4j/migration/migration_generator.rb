require File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'neo4j.rb')

module Neo4j
  module Generators
    class MigrationGenerator < ::Rails::Generators::NamedBase
      include ::Neo4j::Generators::SourcePathHelper
      include ::Neo4j::Generators::MigrationHelper

      def create_migration_file
        migration_template 'migration.erb'
      end
    end
  end
end
