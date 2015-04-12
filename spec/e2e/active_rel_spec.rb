require 'spec_helper'

describe 'ActiveRel' do
  before(:each) do
    clear_model_memory_caches
    delete_db

    stub_named_class('ToClass')

    stub_named_class('MyRelClass')

    stub_active_node_class('FromClass') do
      has_many :out, :others, model_class: 'ToClass', rel_class: 'MyRelClass'
    end

    stub_active_node_class('ToClass') do
      has_many :in, :others, model_class: 'FromClass', rel_class: 'MyRelClass'
      has_many :in, :string_others, model_class: 'FromClass', rel_class: 'MyRelClass'
    end

    stub_active_rel_class('MyRelClass') do
      from_class 'FromClass'
      to_class 'ToClass'
      type 'rel_class_type'

      property :score
      property :links
      serialize :links
    end
  end

  let(:from_node) { FromClass.create }
  let(:to_node) { ToClass.create }

  describe 'creation' do
    context 'from_node is not persisted' do
      let(:from_node) { FromClass.new }

      it 'raises an error when it cannot create a rel' do
        expect { MyRelClass.create(from_node: from_node, to_node: to_node) }.to raise_error Neo4j::ActiveRel::Persistence::RelCreateFailedError
      end
    end

    describe 'creates_unique_rel' do
      after do
        MyRelClass.instance_variable_set(:@unique, false)
        [from_node, to_node].each(&:destroy)
      end

      it 'creates a unique relationship between to nodes' do
        expect(from_node.others.count).to eq 0
        MyRelClass.create(from_node: from_node, to_node: to_node)
        expect(from_node.others.count).to eq 1
        MyRelClass.creates_unique_rel
        MyRelClass.create(from_node: from_node, to_node: to_node)
        expect(from_node.others.count).to eq 1
      end
    end
  end

  describe 'properties' do
    it 'serializes' do
      rel = MyRelClass.create(from_node: from_node, to_node: to_node)
      rel.links = {search: 'https://google.com', social: 'https://twitter.com'}
      expect { rel.save }.not_to raise_error
      rel.reload
      expect(rel.links).to be_a(Hash)
      rel.destroy
    end
  end

  describe 'types' do
    before(:each) do
      stub_active_rel_class('AutomaticRelType') do
        from_class 'FromClass'
        to_class 'ToClass'
      end

      stub_named_class('InheritedRelClass', AutomaticRelType)
    end

    it 'allows omission of `type`' do
      expect(AutomaticRelType._type).to eq 'AUTOMATIC_REL_TYPE'
    end

    it 'uses `type` to override the default type' do
      AutomaticRelType.type 'NEW_TYPE'
      expect(AutomaticRelType._type).to eq 'NEW_TYPE'
    end

    it 'uses the defined class name when inheriting' do
      expect(InheritedRelClass._type).to eq 'INHERITED_REL_CLASS'
    end
  end

  describe 'associations with rel_class set' do
    context 'with rel created from node' do
      let(:f1) { FromClass.create }
      let(:t1) { ToClass.create }
      before { f1.others << t1 }
      after { f1.destroy && t1.destroy }

      it 'returns the activerel class' do
        expect(f1.others.rels.first).to be_a(MyRelClass)
      end

      it 'correctly interprets strings as class names' do
        t1.string_others << f1
        expect(t1.string_others.count).to eq 2
      end
    end

    context 'with rel created from activerel' do
      let(:rel) { MyRelClass.create(from_node: from_node, to_node: to_node) }

      after(:each) { rel.destroy }
      it 'creates the rel' do
        expect(rel.from_node).to eq from_node
        expect(rel.to_node).to eq to_node
        expect(rel.persisted?).to be_truthy
      end

      it 'update the rel' do
        rel.score = 9000
        rel.save && rel.reload
        expect(rel.score).to eq 9000
      end

      it 'has a valid _persisted_obj' do
        expect(rel._persisted_obj).not_to be_nil
      end
    end
  end

  describe 'objects and queries' do
    before do
      Neo4j::Config[:cache_class_names] = true
      @rel1 = MyRelClass.create(from_node: from_node, to_node: to_node, score: 99)
      @rel2 = MyRelClass.create(from_node: from_node, to_node: to_node, score: 49)
    end

    after { [@rel1, @rel2].each(&:destroy) }

    describe 'related nodes' do
      # We only run this test in the Server environment. Embedded's loading of
      # relationships works differently, so we aren't as concerned with whether
      # it is loading two extra nodes.
      it 'does not load when calling neo_id from Neo4j Server' do
        unless Neo4j::Session.current.db_type == :embedded_db
          reloaded = MyRelClass.find(@rel1.neo_id)
          expect(reloaded.from_node).not_to be_loaded
          expect(reloaded.from_node.neo_id).to eq from_node.neo_id
          expect(reloaded.from_node.loaded?).to be_falsey
        end
      end
    end

    describe 'where' do
      it 'returns the matching objects' do
        expect(MyRelClass.where(score: 99)).to eq [@rel1]
      end

      it 'has the appropriate from and to nodes' do
        rel = MyRelClass.where(score: 99).first
        expect(rel.from_node).to eq from_node
        expect(rel.to_node).to eq to_node
      end

      context 'with a string' do
        it 'returns the matching rels' do
          query = MyRelClass.where('r1.score > 48')
          expect(query).to include(@rel1, @rel2)
        end
      end
    end

    describe 'all' do
      it 'returns all rels' do
        query = MyRelClass.all
        expect(query).to include(@rel1, @rel2)
      end
    end

    describe 'find' do
      it 'returns the rel' do
        expect(MyRelClass.find(@rel1.neo_id)).to eq @rel1
      end
    end

    describe 'first, last' do
      it 'returns the first-ish result' do
        expect(MyRelClass.first).to eq @rel1
      end

      it 'returns the last-ish result' do
        expect(MyRelClass.last).to eq @rel2
      end

      context 'with from_class and to_class as strings and constants' do
        it 'converts the strings to constants and runs the query' do
          MyRelClass.from_class 'FromClass'
          MyRelClass.to_class 'ToClass'
          expect(MyRelClass.where(score: 99)).to eq [@rel1]

          MyRelClass.from_class :FromClass
          MyRelClass.to_class :ToClass
          expect(MyRelClass.where(score: 99)).to eq [@rel1]
        end
      end
    end
  end
end
