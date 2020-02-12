
describe 'migration tasks' do
  let_env_variable('MIGRATIONS_SILENCED') { 'true' }

  before do
    clear_model_memory_caches

    stub_active_node_class('User') do
      property :name
      has_many :out, :songs, model_class: :Song, type: 'songs'
    end

    stub_active_node_class('Song') do
      property :name

      has_many :in, :owners, model_class: :User, origin: :songs
      has_many :out, :singers, model_class: :User, rel_class: :oSecondRelClass
      has_many :out, :new_singers, model_class: :User, rel_class: :ThirdRelClass
      def custom_id
        'my new id'
      end
    end

    stub_active_rel_class('FirstRelClass') do
      from_class false
      to_class false
      type 'songs'
    end

    stub_active_rel_class('SecondRelClass') do
      from_class false
      to_class false
      type 'singers'
    end

    stub_active_rel_class('ThirdRelClass') do
      from_class false
      to_class false
      type 'singers'
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
    before do
      Neo4j::Config.delete(:id_property)
      Neo4j::Config.delete(:id_property_type)
      Neo4j::Config.delete(:id_property_type_value)
    end

    let(:full_path) { '/hd/gems/rails/add_id_property.yml' }
    let(:clazz) { Neo4j::Migration::AddIdProperty }
    let(:map_template) { {models: %w(User Song)} }

    before do
      allow(Rails).to receive_message_chain(:root, :join).and_return('/hd/gems/rails/add_id_property.yml')
      allow(YAML).to receive(:load_file).and_return(map_template)
    end

    it 'loads an initialization file' do
      expect(Rails).to receive(:root).and_return(path)
      expect { clazz.new }.not_to raise_error
    end

    it 'adds ids when missing based on label' do
      Neo4j::Transaction.query('CREATE (n:`User`) return n')
      user = User.first
      neo_id = user.neo_id
      expect(user.uuid).to be_nil
      clazz.new.migrate

      user = User.first
      expect(user.uuid).not_to be_nil
      expect(user.neo_id).to eq neo_id
    end

    it 'does not modify existing ids' do
      user = User.create
      expect(user.uuid).not_to be_nil
      uuid = user.uuid

      clazz.new.migrate
      user_again = User.find(uuid)
      expect(user_again.uuid).to eq user.uuid
    end

    it 'respects the id_property declared on the model' do
      create_constraint :Song, :my_id, type: :unique

      Song.id_property :my_id, on: :custom_id
      Neo4j::Transaction.query('CREATE (n:`Song`) return n')
      user = Song.first
      neo_id = user.neo_id
      expect(user).not_to respond_to(:uuid)
      expect(user.my_id).to be_nil

      clazz.new.migrate
      user = Song.first
      expect(user.my_id).to eq 'my new id'
      expect(user.neo_id).to eq neo_id
    end
  end
end
