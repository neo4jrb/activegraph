module Neo4j
  module Migrations
    describe 'Neo4j::Migrations' do
      before { delete_schema }

      capture_output!(:output_string)

      before do
        create_constraint :'Neo4j::Migrations::SchemaMigration', :migration_id, type: :unique

        create_constraint :User, :uuid, type: :unique
        create_constraint :User, :name, type: :unique
        stub_active_node_class('User') do
          property :name
        end

        allow(Runner).to receive(:files_path) do
          Rails.root.join('spec', 'migration_files', 'migrations', '*.rb')
        end
        User.delete_all
        SchemaMigration.delete_all
      end

      let(:all_migrations_on!) do
        SchemaMigration.create! migration_id: '1234567890'
        SchemaMigration.create! migration_id: '9500000000'
        SchemaMigration.create! migration_id: '9500000001'
      end

      describe '#maintain_test_schema!' do
        it 'checks and runs pending migrations' do
          expect do
            Neo4j::Migrations.maintain_test_schema!
          end.to change { SchemaMigration.count }.by(3)
        end
      end

      describe '#check_for_pending_migrations!' do
        it 'fails with a PendingMigrationError for rails >= 5' do
          allow(Rails).to receive(:version).and_return('5.0.0')
          expect do
            Neo4j::Migrations.check_for_pending_migrations!
          end.to raise_error(PendingMigrationError, %r{bin/rails neo4j:migrate})
        end

        it 'fails with a PendingMigrationError for rails < 5' do
          allow(Rails).to receive(:version).and_return('4.0.0')
          expect do
            Neo4j::Migrations.check_for_pending_migrations!
          end.to raise_error(PendingMigrationError, %r{bin/rake neo4j:migrate})
        end

        it 'fails with a PendingMigrationError for non-rails' do
          allow_any_instance_of(PendingMigrationError).to receive(:rails?).and_return(false)
          expect do
            Neo4j::Migrations.check_for_pending_migrations!
          end.to raise_error(PendingMigrationError, /rake neo4j:migrate/)
        end
      end

      describe Runner do
        describe '#pending_migrations' do
          it 'returns a list of pending migrations' do
            SchemaMigration.create! migration_id: '1234567890'
            expect(described_class.new.pending_migrations).to eq(%w(9500000000 9500000001))
          end

          it 'returns an empty list if all migrations are up' do
            all_migrations_on!
            expect(described_class.new.pending_migrations).to be_empty
          end
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
            SchemaMigration.create! migration_id: '1234567890', incomplete: true
            SchemaMigration.create! migration_id: '9500000000'
            SchemaMigration.create! migration_id: '9400000000'
          end

          it 'prints the current migration status' do
            described_class.new.status
            expect(output_string).to match(/^\s*incomplete\s*1234567890\s*RenameJohnJack$/)
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

          it 'prints queries and execution time' do
            described_class.new.up '9500000000'
            expect(output_string).to include('MATCH (u:`User`)')
            expect(output_string).to match(/migrated \(\d.\d+s\)/)
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

        describe 'schema changes in migrations' do
          before do
            allow(described_class).to receive(:files_path) do
              Rails.root.join('spec', 'migration_files', 'transactional_migrations', '*.rb')
            end
          end

          it 'run `up` without raising errors' do
            expect do
              expect do
                described_class.new.up '8888888888'
              end.not_to raise_error
            end.to change { Neo4j::Core::Label.new(:Book, current_driver).constraint?(:some) }.to(true)
          end

          it 'run `down` without raising errors' do
            create_constraint :Book, :some, type: :unique
            SchemaMigration.create! migration_id: '8888888888'
            expect do
              expect do
                described_class.new.down '8888888888'
              end.not_to raise_error
            end.to change { Neo4j::Core::Label.new(:Book, current_driver).constraint?(:some) }.to(false)
          end
        end

        describe 'failure' do
          it 'Removes SchemaMigration when there is a failure' do
            allow_any_instance_of(Neo4j::Migrations::Base).to receive(:execute).and_raise('SURPRISE!')
            expect { described_class.new.up '9500000000' }.to raise_error('SURPRISE!')

            expect(SchemaMigration.find_by(migration_id: '9500000000')).to be_nil
          end

          it 'Rolls back SchemaMigration to being complete when there is a failure' do
            described_class.new.up '9500000000'

            allow_any_instance_of(Neo4j::Migrations::Base).to receive(:execute).and_raise('SURPRISE!')
            expect { described_class.new.down '9500000000' }.to raise_error('SURPRISE!')

            expect(SchemaMigration.find_by(migration_id: '9500000000').incomplete).to be_nil
          end

          context 'transaction migrations' do
            before do
              allow(described_class).to receive(:files_path) do
                Rails.root.join('spec', 'migration_files', 'transactional_migrations', '*.rb')
              end
            end

            it 'Leaves SchemaMigration as incomplete when there is a failure in a non-transactional migration up' do
              allow_any_instance_of(Neo4j::Migrations::Base).to receive(:execute).and_raise('SURPRISE!')
              expect { described_class.new.up '1231231232' }.to raise_error('SURPRISE!')

              expect(SchemaMigration.find_by(migration_id: '1231231232').incomplete).to be true
            end

            it 'Leaves SchemaMigration as incomplete when there is a failure in a non-transactional migration down' do
              described_class.new.up '1231231232'
              allow_any_instance_of(Neo4j::Migrations::Base).to receive(:execute).and_raise('SURPRISE!')
              expect { described_class.new.down '1231231232' }.to raise_error('SURPRISE!')

              expect(SchemaMigration.find_by(migration_id: '1231231232').incomplete).to be true
            end
          end

          describe '#resolve' do
            it 'fixes incomplete states' do
              migration = SchemaMigration.create! migration_id: 'some', incomplete: true
              SchemaMigration.find_by!(migration_id: migration.migration_id)

              expect do
                described_class.new.resolve 'some'
              end.to change { migration.reload.incomplete }.to(false)
            end
          end

          describe '#reset' do
            it 'rollbacks incomplete states' do
              SchemaMigration.create! migration_id: 'some', incomplete: true
              expect do
                described_class.new.reset 'some'
              end.to change { SchemaMigration.count }.by(-1)
            end
          end
        end

        describe 'schema and data changes in migrations' do
          before do
            allow(described_class).to receive(:files_path) do
              Rails.root.join('spec', 'migration_files', 'transactional_migrations', '*.rb')
            end
          end

          it 'run correctly when transactions are disabled' do
            described_class.new.up '9999999999'
          end

          it 'fails with a custom error message when transactions are enabled' do
            expect do
              described_class.new.up '0000000000'
            end.to raise_error(/Please add `disable_transactions!`/)
          end
        end

        describe 'transactional behavior in migrations' do
          before do
            stub_active_node_class('Contact') do
              property :phone
            end

            Contact.delete_all
            create_constraint :Contact, :uuid, type: :unique
            create_constraint :Contact, :phone, type: :unique
            Contact.create! phone: '123123'

            allow(described_class).to receive(:files_path) do
              Rails.root.join('spec', 'migration_files', 'transactional_migrations', '*.rb')
            end
          end

          let!(:joe) { User.create! name: 'Joe' }

          it 'rollbacks any change when one of the queries fails' do
            expect do
              expect { described_class.new.up '1231231231' }.to raise_error(/already exists/)
            end.to not_change { joe.reload.name } & not_change { SchemaMigration.count }
          end

          it 'rollbacks nothing when transactions are disabled' do
            expect do
              expect { described_class.new.up '1231231232' }.to raise_error(/already exists/)
            end.to change { joe.reload.name }.to('Jack') & change { SchemaMigration.count }.by(1)
          end
        end
      end
    end
  end
end
