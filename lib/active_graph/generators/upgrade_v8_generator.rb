module ActiveGraph
  module Generators
    class UpgradeV8Generator < ::Rails::Generators::Base
      include ::ActiveGraph::Generators::SourcePathHelper
      include ::ActiveGraph::Generators::MigrationHelper

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
        ActiveGraph::ModelSchema.legacy_model_schema_informations
      end

      def initialize_all_models!
        models = ActiveGraph::Node.loaded_classes
        models.map(&:ensure_id_property_info!)
      end
    end
  end
end
