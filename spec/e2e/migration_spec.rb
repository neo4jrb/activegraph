describe 'migration tasks' do
  require 'neo4j/migration'

  before(:all) { ENV['silenced'] = 'true' }
  after(:all)  { ENV['silenced'] = nil }

  before do
    module MigrationSpecs
      class Song; end
      class SecondRelClass; end
      class ThirdRelClass; end

      class User
        include Neo4j::ActiveNode
        property :name
        has_many :out, :songs, model_class: :Song, type: 'songs'
      end

      class Song
        include Neo4j::ActiveNode
        property :name

        has_many :in, :owners, model_class: :User, origin: :songs
        has_many :out, :singers, model_class: :User, rel_class: 'MigrationSpecs::SecondRelClass'
        has_many :out, :new_singers, model_class: :User, rel_class: 'MigrationSpecs::ThirdRelClass'
        def custom_id
          'my new id'
        end
      end

      class FirstRelClass
        include Neo4j::ActiveRel
        from_class false
        to_class false
        type 'songs'
      end

      class SecondRelClass
        include Neo4j::ActiveRel
        from_class false
        to_class false
        type 'singers'
      end

      class ThirdRelClass
        include Neo4j::ActiveRel
        from_class false
        to_class false
        type 'singers'
      end
    end
  end

  let(:Rails) { double('Doubles the Rails constant') }
  let(:File)  { double('Doubles the File constant') }
  let(:path)  { '/hd/gems/rails' }

  describe 'base Migration class' do
    it 'raises an error' do
      expect { Neo4j::Migration.new.migrate }.to raise_error 'not implemented'
    end
  end

  describe 'AddIdProperty class' do
    let(:full_path) { '/hd/gems/rails/add_id_property.yml' }
    let(:clazz) { Neo4j::Migration::AddIdProperty }
    let(:map_template) { {models: ['MigrationSpecs::User', 'MigrationSpecs::Song']} }

    before do
      allow(Rails).to receive_message_chain(:root, :join).and_return('/hd/gems/rails/add_id_property.yml')
      allow(YAML).to receive(:load_file).and_return(map_template)
    end

    it 'loads an initialization file' do
      expect(Rails).to receive(:root).and_return(path)
      expect { clazz.new }.not_to raise_error
    end

    it 'adds ids when missing based on label' do
      Neo4j::Session.query('CREATE (n:`MigrationSpecs::User`) return n')
      user = MigrationSpecs::User.first
      neo_id = user.neo_id
      expect(user.uuid).to be_nil
      clazz.new.migrate

      user = MigrationSpecs::User.first
      expect(user.uuid).not_to be_nil
      expect(user.neo_id).to eq neo_id
    end

    it 'does not modify existing ids' do
      user = MigrationSpecs::User.create
      expect(user.uuid).not_to be_nil
      uuid = user.uuid

      clazz.new.migrate
      user_again = MigrationSpecs::User.find(uuid)
      expect(user_again).to eq user
    end

    it 'respects the id_property declared on the model' do
      MigrationSpecs::Song.id_property :my_id, on: :custom_id
      Neo4j::Session.query('CREATE (n:`MigrationSpecs::Song`) return n')
      user = MigrationSpecs::Song.first
      neo_id = user.neo_id
      expect(user).not_to respond_to(:uuid)
      expect(user.my_id).to be_nil

      clazz.new.migrate
      user = MigrationSpecs::Song.first
      expect(user.my_id).to eq 'my new id'
      expect(user.neo_id).to eq neo_id
    end
  end
end
