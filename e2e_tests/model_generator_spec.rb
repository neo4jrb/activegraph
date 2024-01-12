load 'myapp/app/models/user.rb'
load_migration('create_user.rb')

describe 'Model Generator' do
  describe 'generated model class' do
    it 'includes ActiveGraph::Node' do
      expect(User < ActiveGraph::Node).to be true
    end

    it 'declares correct property' do
      expect(User.attributes['name'].type).to be String
    end
  end

  describe 'generated migration file' do
    it 'inherits from ActiveGraph::Migrations::Base' do
      expect(CreateUser).to be < ActiveGraph::Migrations::Base
    end

    it 'can be run/rollback without issue' do
      migration = CreateUser.new(nil)
      expect do
        migration.up
        migration.down
      end.not_to raise_error
    end
  end
end
