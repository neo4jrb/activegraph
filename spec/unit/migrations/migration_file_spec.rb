describe ActiveGraph::Migrations::MigrationFile do
  let(:file_name) do
    "#{Rails.root}/spec/migration_files/transactional_migrations/1231231232_failing_migration_without_transactions.rb"
  end
  subject { described_class.new(file_name) }

  its(:version) { is_expected.to eq('1231231232') }
  its(:symbol_name) { is_expected.to eq('failing_migration_without_transactions') }
  its(:class_name) { is_expected.to eq('FailingMigrationWithoutTransactions') }
  its(:create) { is_expected.to be_a(FailingMigrationWithoutTransactions) }
end
