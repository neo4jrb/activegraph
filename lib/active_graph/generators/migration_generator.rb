module ActiveGraph
  module Generators
    class MigrationGenerator < ::Rails::Generators::NamedBase
      include ::ActiveGraph::Generators::SourcePathHelper
      include ::ActiveGraph::Generators::MigrationHelper

      def create_migration_file
        migration_template 'migration.erb'
      end
    end
  end
end
