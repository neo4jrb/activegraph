require File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'neo4j.rb')

module Neo4j
  module Generators
    class UpgradeV8Generator < ::Rails::Generators::Base
      include ::Neo4j::Generators::SourcePathHelper
      include ::Neo4j::Generators::MigrationHelper

      def create_upgrade_v8_file
        @schema = load_all_models_schema!
        migration_template 'migration.erb'
      end

      def file_name
        'upgrate_to_v8'
      end

      private

      def load_all_models_schema!
        Rails.application.eager_load!
        initialize_all_models!
        Neo4j::ModelSchema.legacy_model_schema_informations
      end

      def initialize_all_models!
        models = Neo4j::ActiveNode.loaded_classes
        models.map(&:ensure_id_property_info!)
      end
    end
  end
end
