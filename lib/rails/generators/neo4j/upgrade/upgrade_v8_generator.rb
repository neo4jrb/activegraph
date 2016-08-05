require File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'neo4j.rb')

class Neo4j::Generators::UpgradeV8Generator < Rails::Generators::Base
  include Neo4j::Generators::Migration

  def create_neo4j_migration_file
    @constraints_and_indexes = load_all_models_schema!
    migration_template '../../migration/templates/migration.erb'
  end

  def file_name
    'upgrate_to_v8'
  end

  private

  def load_all_models_schema!
    Rails.application.eager_load!
    descendants = ObjectSpace.each_object(Class).select { |klass| klass < Neo4j::ActiveNode }
    descendants.each_with_object([]) do |model, schema|
      model_schema = model.legacy_model_schema_informations
      schema[:constraints] += model_schema[:constraints]
      schema[:indexes] += model_schema[:indexes]
    end
  end
end
