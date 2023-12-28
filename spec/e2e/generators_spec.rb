require 'rails/generators/active_graph/model/model_generator'
require 'rails/generators/active_graph/migration/migration_generator'
require 'rails/generators/active_graph/upgrade_v8/upgrade_v8_generator'

describe 'Generators' do
  around do |example|
    Timecop.freeze(Time.parse('1990-12-10 00:00:00 -0000')) { example.run }
  end

  describe ActiveGraph::Generators::ModelGenerator do
    it 'has a `source_root`' do
      expect(described_class.source_root).to include('rails/generators/active_graph/model/templates')
    end

    it 'creates a model and a migration file' do
      expect_any_instance_of(described_class).to receive(:template).with('model.erb', 'app/models/some.rb')
      expect_any_instance_of(described_class).to receive(:template).with('migration.erb', 'db/neo4j/migrate/19901210000000_create_some.rb')
      described_class.new(['some']).create_model_file
    end
  end

  describe ActiveGraph::Generators::MigrationGenerator do
    it 'has a `source_root`' do
      expect(described_class.source_root).to include('rails/generators/active_graph/migration/templates')
    end

    it 'creates a migration file' do
      expect_any_instance_of(described_class).to receive(:template).with('migration.erb', 'db/neo4j/migrate/19901210000000_some.rb')
      described_class.new(['some']).create_migration_file
    end
  end

  describe ActiveGraph::Generators::UpgradeV8Generator do
    before do
      app = double
      allow(app).to receive(:eager_load!) do
        stub_node_class('Person') do
          property :name, index: :exact
        end
      end
      allow(Rails).to receive(:application).and_return(app)
    end

    it 'has a `source_root`' do
      expect(described_class.source_root).to include('rails/generators/active_graph/upgrade_v8/templates')
    end

    it 'creates a migration file' do
      expect_any_instance_of(described_class).to receive(:template).with('migration.erb', 'db/neo4j/migrate/19901210000000_upgrate_to_v8.rb')
      described_class.new.create_upgrade_v8_file
    end
  end
end
