module Neo4j
  module Migrations
    describe Runner do
      before { delete_schema }

      let_env_variable('MIGRATIONS_SILENCED') { 'true' }

      before do
        create_constraint :'Neo4j::Migrations::SchemaMigration', :migration_id, type: :unique

        create_constraint :User, :uuid, type: :unique
        stub_active_node_class('User') do
          property :name
        end

        allow_any_instance_of(described_class).to receive(:files_path) do
          Rails.root.join('spec', 'support', 'migrations', '*.rb')
        end
        SchemaMigration.delete_all
      end

      let(:all_migrations_on!) do
        SchemaMigration.create! migration_id: '1234567890'
        SchemaMigration.create! migration_id: '9500000000'
        SchemaMigration.create! migration_id: '9500000001'
      end

      describe '#all' do
        it 'runs all migrations sorted by version' do
          u = User.create! name: 'John'
          expect do
            described_class.new.all
          end.to change { SchemaMigration.count }.by(3)
            .and(change { u.reload.name }.to('Frank'))
        end

        it 'skips up migrations' do
          u = User.create! name: 'Jack'
          SchemaMigration.create! migration_id: '1234567890'
          expect do
            described_class.new.all
          end.to change { Neo4j::Migrations::SchemaMigration.count }.by(2)
            .and(change { u.reload.name }.to('Frank'))
        end
      end

      describe '#status' do
        before do
          SchemaMigration.create! migration_id: '1234567890'
          SchemaMigration.create! migration_id: '9500000000'
          SchemaMigration.create! migration_id: '9400000000'
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
            .and(change { SchemaMigration.count }.by(1))
        end

        it 'runs a certain migration version' do
          u = User.create! name: 'Jack'
          expect do
            described_class.new.up '9500000000'
          end.to change { u.reload.name }.to('Bob')
            .and(change { SchemaMigration.count }.by(1))
        end

        it 'fails when passing a missing version' do
          expect { described_class.new.up '123123' }.to raise_error(
            ::Neo4j::UnknownMigrationVersionError, 'No such migration 123123')
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
          expect { described_class.new.down '1234567890' }.to raise_error(::Neo4j::IrreversibleMigration)
        end
      end

      describe '#rollback' do
        it 'rollbacks migrations given a number of steps' do
          all_migrations_on!
          u = User.create! name: 'Frank'
          expect do
            described_class.new.rollback 2
          end.to change { SchemaMigration.count }.by(-2)
            .and(change { u.reload.name }.to('Jack'))
        end
      end

      describe 'transactional behavior in migrations' do
        before do
          create_constraint :Contact, :uuid, type: :unique
          create_constraint :Contact, :phone, type: :unique
          stub_active_node_class('Contact') do
            property :phone
          end

          Contact.delete_all
          Contact.create! phone: '123123'

          allow_any_instance_of(described_class).to receive(:files_path) do
            Rails.root.join('spec', 'support', 'transactional_migrations', '*.rb')
          end
        end

        it 'rollbacks any change when one of the queries fails' do
          joe = User.create! name: 'Joe'
          expect do
            expect { described_class.new.up '1231231231' }.to raise_error(/already exists/)
          end.not_to change { joe.reload.name }
        end

        it 'rollbacks nothing when transactions are disabled' do
          joe = User.create! name: 'Joe'
          expect do
            expect { described_class.new.up '1234567890' }.to raise_error(/already exists/)
          end.to change { joe.reload.name }.to('Jack')
        end
      end
    end
  end
end
