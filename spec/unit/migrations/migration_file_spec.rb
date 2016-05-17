describe Neo4j::Migrations::MigrationFile do
  let(:file_name) do
    "#{Rails.root}/spec/support/transactional_migrations/1234567890_migration_without_transactions.rb"
  end
  subject { described_class.new(file_name) }

  its(:version) { is_expected.to eq('1234567890') }
  its(:symbol_name) { is_expected.to eq('migration_without_transactions') }
  its(:class_name) { is_expected.to eq('MigrationWithoutTransactions') }
  its(:create) { is_expected.to be_a(MigrationWithoutTransactions) }
end
