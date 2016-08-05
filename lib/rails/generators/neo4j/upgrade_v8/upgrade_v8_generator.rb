require File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'neo4j.rb')

module Neo4j
  module Generators
    class UpgradeV8 < ::Neo4j::Generators::Base
      include ::Neo4j::Generators::MigrationHelper

      def create_neo4j_migration_file
        @schema = load_all_models_schema!
        migration_template 'migration.erb'
      end

      def file_name
        'upgrate_to_v8'
      end

      private

      def load_all_models_schema!
        Rails.application.eager_load!
        Neo4j::ModelSchema.legacy_model_schema_informations
      end
    end
  end
end
