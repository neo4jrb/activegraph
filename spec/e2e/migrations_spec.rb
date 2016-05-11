describe Neo4j::Migrations::Runner do
  before(:all) { ENV['silenced'] = 'true' }
  after(:all)  { ENV['silenced'] = nil }

  before do
    stub_active_node_class('User') do
      property :name
    end

    allow_any_instance_of(described_class).to receive(:files_path) do
      Rails.root.join('spec', 'support', 'migrations', '*.rb')
    end
    Neo4j::Migrations::SchemaMigration.delete_all
  end

  let(:all_migrations_on!) do
    Neo4j::Migrations::SchemaMigration.create! migration_id: '1234567890'
    Neo4j::Migrations::SchemaMigration.create! migration_id: '9500000000'
    Neo4j::Migrations::SchemaMigration.create! migration_id: '9500000001'
  end

  describe '#all' do
    it 'runs all migrations sorted by version' do
      u = User.create! name: 'John'
      expect do
        described_class.new.all
      end.to change { Neo4j::Migrations::SchemaMigration.count }.by(3)
        .and(change { u.reload.name }.to('Frank'))
    end

    it 'skips up migrations' do
      u = User.create! name: 'Jack'
      Neo4j::Migrations::SchemaMigration.create! migration_id: '1234567890'
      expect do
        described_class.new.all
      end.to change { Neo4j::Migrations::SchemaMigration.count }.by(2)
        .and(change { u.reload.name }.to('Frank'))
    end
  end

  describe '#status' do
    before do
      Neo4j::Migrations::SchemaMigration.create! migration_id: '1234567890'
      Neo4j::Migrations::SchemaMigration.create! migration_id: '9500000000'
      Neo4j::Migrations::SchemaMigration.create! migration_id: '9400000000'
    end

    it 'prints the current migration status' do
      output_string = ''
      allow_any_instance_of(described_class).to receive(:output) do |_, *args|
        output_string += format(*args) + "\n"
      end
      described_class.new.status
      expect(output_string).to match(/^\s*up\s*1234567890\s*RenameJohnJack$/)
      expect(output_string).to match(/^\s*down\s*9500000001\s*RenameBobFrank/)
      expect(output_string).to match(/^\s*up\s*9400000000\s*\*\*\*\* file missing \*\*\*\*/)
    end
  end

  describe '#up' do
    it 'runs a certain migration version' do
      u = User.create! name: 'Jack'
      expect do
        described_class.new.up '9500000000'
      end.to change { u.reload.name }.to('Bob')
        .and(change { Neo4j::Migrations::SchemaMigration.count }.by(1))
    end

    it 'runs a certain migration version' do
      u = User.create! name: 'Jack'
      expect do
        described_class.new.up '9500000000'
      end.to change { u.reload.name }.to('Bob')
        .and(change { Neo4j::Migrations::SchemaMigration.count }.by(1))
    end

    it 'fails when passing a missing version' do
      expect { described_class.new.up '123123' }.to raise_error(
        Neo4j::UnknownMigrationVersionError, 'No such migration 123123')
    end
  end

  describe '#down' do
    before { all_migrations_on! }

    it 'runs a certain migration version' do
      u = User.create! name: 'Bob'
      expect do
        described_class.new.down '9500000000'
      end.to change { u.reload.name }.to('Jack')
    end

    it 'fails when passing a missing version' do
      expect { described_class.new.down '123123' }.to raise_error(
        Neo4j::UnknownMigrationVersionError, 'No such migration 123123')
    end

    it 'fails on irreversible migrations' do
      expect { described_class.new.down '1234567890' }.to raise_error(Neo4j::IrreversibleMigration)
    end
  end

  describe '#rollback' do
    it 'rollbacks migrations given a number of steps' do
      all_migrations_on!
      u = User.create! name: 'Frank'
      expect do
        described_class.new.rollback 2
      end.to change { Neo4j::Migrations::SchemaMigration.count }.by(-2)
        .and(change { u.reload.name }.to('Jack'))
    end
  end
end
