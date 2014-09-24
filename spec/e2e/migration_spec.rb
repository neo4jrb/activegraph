require 'spec_helper'

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
        has_many :out, :songs, model_class: Song, type: 'songs'
      end

      class Song
        include Neo4j::ActiveNode
        property :name

        has_many :in, :owners, model_class: User, origin: :songs
        has_many :out, :singers, model_class: User, rel_class: MigrationSpecs::SecondRelClass
        has_many :out, :new_singers, model_class: User, rel_class: MigrationSpecs::ThirdRelClass
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

      def self.classname_count(label)
        Proc.new { Neo4j::Session.query("MATCH (n:`#{label}`) WHERE n._classname = '#{label}' RETURN COUNT(n) as countable").first.countable }
      end
    end
  end

  let(:Rails) { double('Doubles the Rails constant') }
  let(:File)  { double('Doubles the File constant')}
  let(:path)  { '/hd/gems/rails' }

  describe 'base Migration class' do
    it 'raises an error' do
      expect{Neo4j::Migration.new.migrate}.to raise_error 'not implemented'
    end
  end

  describe 'AddIdProperty class' do
    let(:full_path) { '/hd/gems/rails/add_id_property.yml' }
    let(:clazz) { Neo4j::Migration::AddIdProperty }
    let(:map_template) { { models: ['MigrationSpecs::User','MigrationSpecs::Song'] } }

    before do
      Rails.stub_chain(:root, :join).and_return('/hd/gems/rails/add_id_property.yml')
      YAML.stub(:load_file).and_return(map_template)
    end

    it 'loads an initialization file' do
      expect(Rails).to receive(:root).and_return(path)
      expect(path).to receive(:join).with('db', 'neo4j-migrate').and_return(full_path)
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

  describe 'AddClassnames class' do
    let(:full_path) { '/hd/gems/rails/add_classnames.yml' }
    let(:clazz) { Neo4j::Migration::AddClassnames }
    let(:map_template) do 
      {  
        nodes: { 'add' => ['MigrationSpecs::User'], 'overwrite' => ['MigrationSpecs::Song'] },
        relationships: {
          'add' =>       {  'MigrationSpecs::FirstRelClass' => { :type => 'songs' } },
          'overwrite' => { 'MigrationSpecs::ThirdRelClass' => { :type => 'singers' } }
        }
      }
    end
    let(:tony)     { MigrationSpecs::User.create(name: 'Tony') }
    let(:ronnie)   { MigrationSpecs::User.create(name: 'Ronnie') }
    let(:children) { MigrationSpecs::Song.create(name: 'Children of the Sea') }
    let(:neon)     { MigrationSpecs::Song.create(name: 'Neon Knights') }

    before do
      Rails.stub_chain(:root, :join).and_return('/hd/gems/rails/add_classnames.yml')
      YAML.stub(:load_file).and_return(map_template)
      clazz.any_instance.stub(:file_init).and_return(map_template)
      clazz.any_instance.stub(:model_map).and_return(map_template)
      clazz.any_instance.instance_variable_set(:@model_map, map_template)
    end

    after(:each) do
      MigrationSpecs::User.destroy_all
      MigrationSpecs::Song.destroy_all
    end

    it 'loads an initialization file' do
      expect{ clazz.new }.not_to raise_error
    end

    describe 'nodes' do
      it 'adds given classname to nodes' do
        Neo4j::Session.query('CREATE (n:`MigrationSpecs::User`) set n.name = "Geezer" return n')
        geezer_query = MigrationSpecs::classname_count('MigrationSpecs::User')
        expect(geezer_query.call).to eq 0
        clazz.new.migrate
        expect(geezer_query.call).to eq 1
      end

      it 'replaces given classnames' do
        Neo4j::Session.query('CREATE (n:`MigrationSpecs::Song`) set n.name = "Country Girl", n._classname = "Wrong" return n')
        country_query = MigrationSpecs::classname_count('MigrationSpecs::Song')
        expect(country_query.call).to eq 0
        clazz.new.migrate
        expect(country_query.call).to eq 1
      end
    end

    describe 'relationships' do
      it 'adds given classnames to rels' do
        tony.songs << children
        expect(tony.songs(:s, :r).pluck(:r).first).not_to be_a(MigrationSpecs::FirstRelClass)
        expect(tony.songs.first).to eq children
        clazz.new.migrate
        expect(tony.songs(:s, :r).pluck(:r).first).to be_a(MigrationSpecs::FirstRelClass)
      end

      it 'overwrites given classnames on rels' do
        neon.singers << ronnie
        expect(neon.singers(:o, :r).pluck(:r).first).to be_a(MigrationSpecs::SecondRelClass)
        expect(neon.new_singers.count).to eq 0
        clazz.new.migrate
        expect(neon.new_singers.count).to eq 1
        expect(neon.new_singers(:o, :r).pluck(:r).first).to be_a(MigrationSpecs::ThirdRelClass)
      end
    end
  end
end
