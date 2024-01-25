load_migration('blah_migration.rb')

describe 'Migration Generator' do
  describe 'generated migration file' do
    it 'inherits from ActiveGraph::Migrations::Base' do
      expect(BlahMigration).to be < ActiveGraph::Migrations::Base
    end

    it 'defines up method' do
      migration = CreateUser.new(nil)
      expect(migration.method(:up)).to be_present
    end

    it 'defines down method' do
      migration = CreateUser.new(nil)
      expect(migration.method(:up)).to be_present
    end
  end
end
