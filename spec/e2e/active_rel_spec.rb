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
      from_class FromClass
      to_class ToClass
      type 'rel_class_type'

      property :score, type: Integer
      property :links
      serialize :links
    end
  end

  let(:from_node) { FromClass.create }
  let(:to_node) { ToClass.create }

  describe 'from_class, to_class' do
    it 'spits back the current variable if no argument is given' do
      expect(MyRelClass.from_class).to eq FromClass
      expect(MyRelClass.to_class).to eq ToClass
    end

    it 'sets the value with the argument given' do
      expect(MyRelClass.from_class).not_to eq Object
      expect(MyRelClass.from_class(Object)).to eq Object
      expect(MyRelClass.from_class).to eq Object

      expect(MyRelClass.to_class).not_to eq Object
      expect(MyRelClass.to_class(Object)).to eq Object
      expect(MyRelClass.to_class).to eq Object
    end
  end

  describe 'creation' do
    before(:each) do
      stub_active_rel_class('RelClassWithValidations') do
        from_class FromClass
        to_class ToClass
        type 'rel_class_type'

        property :score
        validates :score, presence: true
      end
    end

    describe '#create!' do
      it 'raises an error on invalid params' do
        expect { RelClassWithValidations.create!(from_node: from_node, to_node: to_node) }.to raise_error Neo4j::ActiveRel::Persistence::RelInvalidError
      end
    end

    describe '#save!' do
      it 'raises an error on invalid params' do
        invalid_rel = RelClassWithValidations.new(from_node: from_node, to_node: to_node)
        expect { invalid_rel.save! }.to raise_error Neo4j::ActiveRel::Persistence::RelInvalidError
      end

      it 'returns true on success' do
        rel = RelClassWithValidations.new(from_node: from_node, to_node: to_node, score: 2)
        expect(rel.save!).to be true
      end
    end

    context 'from_node is not persisted' do
      let(:from_node) { FromClass.new }

      it 'raises an error when it cannot create a rel' do
        expect { MyRelClass.create(from_node: from_node, to_node: to_node) }.to raise_error Neo4j::ActiveRel::Persistence::RelCreateFailedError
      end
    end

    describe 'creates_unique' do
      after do
        MyRelClass.instance_variable_set(:@unique, false)
        [from_node, to_node].each(&:destroy)
      end

      it 'creates a unique relationship between to nodes' do
        expect(from_node.others.count).to eq 0
        MyRelClass.create(from_node: from_node, to_node: to_node)
        expect(from_node.others.count).to eq 1
        MyRelClass.creates_unique
        MyRelClass.create(from_node: from_node, to_node: to_node)
        expect(from_node.others.count).to eq 1
      end
    end

    describe 'type checking' do
      # rubocop:disable Metrics/AbcSize
      def self.it_is_expected_to_satisfy(class_method_value)
        context class_method_value.class.to_s do
          before { MyRelClass.from_class(class_method_value) }

          it 'fails when given a mismatched value' do
            expect { MyRelClass.create(from_node: OtherClass.create!, to_node: to_node) }.to raise_error Neo4j::ActiveRel::Persistence::ModelClassInvalidError
          end

          it 'does not fail when given a matching value' do
            expect { MyRelClass.create(from_node: FromClass.create, to_node: to_node) }.not_to raise_error
          end
        end
      end
      # rubocop:enable Metrics/AbcSize

      before { stub_active_node_class('OtherClass') }

      context 'false/:any' do
        it 'does not check for object/class mismatch' do
          [false, :any].each do |c|
            MyRelClass.from_class(c)
            expect { MyRelClass.create(from_node: OtherClass.create!, to_node: to_node) }.not_to raise_error
            expect { MyRelClass.create(from_node: from_node, to_node: to_node) }.not_to raise_error
          end
        end
      end

      it_is_expected_to_satisfy('FromClass')
      it_is_expected_to_satisfy(:FromClass)

      class FromClass; end
      it_is_expected_to_satisfy(FromClass)

      context 'Array' do
        # stub_const does not behave with `it_is_expected_to_satisfy` so making it explicit for now...
        class OtherAcceptableClass
          include Neo4j::ActiveNode
        end

        it_is_expected_to_satisfy([OtherAcceptableClass, FromClass])
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
    # This is the one case I've found so far which you can't use stub_*
    # This is because we're testing the `inherited` hook, and when you stub
    # it is with an anonymous class.  Wtih the anonymous classes, they don't
    # respond to Class.name until after that method is defined, but the inherited
    # hook runs before that point
    # The class constants here are long to disambiguate from other constants in
    # the namespace
    class ActiveRelSpecTypesAutomaticRelType
      include Neo4j::ActiveRel

      from_class 'FromClass'
      to_class 'ToClass'
    end

    class ActiveRelSpecTypesInheritedRelClass < ActiveRelSpecTypesAutomaticRelType
    end

    it 'returns the existing type if arguments are omitted' do
      MyRelClass.type('MY_NEW_TYPE')
      expect(MyRelClass.type).to eq 'MY_NEW_TYPE'
    end

    it 'returns the automatic type if `type` is never called or nil' do
      MyRelClass.instance_variable_set(:'@rel_type', nil)
      expect(MyRelClass.type).to eq 'MY_REL_CLASS'
    end

    it 'uses `type` to override the default type' do
      ActiveRelSpecTypesAutomaticRelType.type 'NEW_TYPE'
      expect(ActiveRelSpecTypesAutomaticRelType._type).to eq 'NEW_TYPE'
    end

    it 'uses the defined class name when inheriting' do
      expect(ActiveRelSpecTypesInheritedRelClass._type).to eq 'ACTIVE_REL_SPEC_TYPES_INHERITED_REL_CLASS'
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

  describe 'initialize' do
    let(:new_rel) { MyRelClass.new(from_node: from_node, to_node: to_node) }

    it 'pulls :from_node and :to_node out of the hash' do
      expect(new_rel.from_node).to eq from_node
      expect(new_rel.to_node).to eq to_node
    end
  end

  describe 'objects and queries' do
    around do |ex|
      ActiveSupport::Deprecation.silenced = true
      ex.run
      ActiveSupport::Deprecation.silenced = false
    end

    let!(:rel1) { MyRelClass.create(from_node: from_node, to_node: to_node, score: 99) }
    let!(:rel2) { MyRelClass.create(from_node: from_node, to_node: to_node, score: 49) }

    after { [rel1, rel2].each(&:destroy) }

    describe 'related nodes' do
      let(:reloaded) { MyRelClass.find(rel1.neo_id) }

      # We only run this test in the Server environment. Embedded's loading of
      # relationships works differently, so we aren't as concerned with whether
      # it is loading two extra nodes.
      it 'does not load when calling neo_id from Neo4j Server' do
        unless Neo4j::Session.current.db_type == :embedded_db
          expect(reloaded.from_node).not_to be_loaded
          expect(reloaded.from_node.neo_id).to eq from_node.neo_id
          expect(reloaded.from_node.loaded?).to be_falsey
        end
      end

      it 'delegates respond_to?' do
        expect(reloaded.from_node.respond_to?(:id)).to be_truthy
      end

      describe 'neo id queries' do
        it 'aliases #{related_node}_neo_id to #{related_node}.neo_id' do
          expect(rel1.from_node_neo_id).to eq rel1.from_node.neo_id
          expect(rel1.to_node_neo_id).to eq rel1.to_node.neo_id
        end
      end
    end

    describe 'where' do
      it 'returns the matching objects' do
        expect(MyRelClass.where(score: 99)).to eq [rel1]
      end

      it 'has the appropriate from and to nodes' do
        rel = MyRelClass.where(score: 99).first
        expect(rel.from_node).to eq from_node
        expect(rel.to_node).to eq to_node
      end

      context 'with a string' do
        it 'returns the matching rels' do
          query = MyRelClass.where('r1.score > 48')
          expect(query).to include(rel1, rel2)
        end
      end
    end

    describe 'all' do
      it 'returns all rels' do
        query = MyRelClass.all
        expect(query).to include(rel1, rel2)
      end
    end

    describe 'find' do
      it 'returns the rel' do
        expect(MyRelClass.find(rel1.neo_id)).to eq rel1
      end
    end

    describe 'first, last' do
      it 'returns the first-ish result' do
        expect(MyRelClass.first).to eq rel1
      end

      it 'returns the last-ish result' do
        expect(MyRelClass.last).to eq rel2
      end

      context 'with from_class and to_class as strings and constants' do
        it 'converts the strings to constants and runs the query' do
          MyRelClass.from_class 'FromClass'
          MyRelClass.to_class 'ToClass'
          expect(MyRelClass.where(score: 99)).to eq [rel1]

          MyRelClass.from_class :FromClass
          MyRelClass.to_class :ToClass
          expect(MyRelClass.where(score: 99)).to eq [rel1]
        end
      end
    end
  end
end
