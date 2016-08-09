describe 'ActiveRel' do
  before(:each) do
    clear_model_memory_caches
    delete_db

    stub_named_class('ToClass')

    stub_active_node_class('FromClass') do
      before_create :log_before
      after_create :log_after
      property :before_run, type: Neo4j::Shared::Boolean
      property :after_run

      has_many :out, :others, model_class: 'ToClass', rel_class: 'MyRelClass'
      has_many :out, :other_others, rel_class: 'MyRelClass'

      def log_before
        self.before_run = true
      end

      def log_after
        self.after_run = true
      end
    end

    stub_active_node_class('ToClass') do
      before_create :log_before
      after_create :log_after
      property :before_run, type: Neo4j::Shared::Boolean
      property :after_run

      has_many :in, :others, model_class: 'FromClass', rel_class: 'MyRelClass'
      has_many :in, :string_others, model_class: 'FromClass', rel_class: 'MyRelClass'

      has_many :out, :other_others, rel_class: 'MyRelClass'

      def log_before
        self.before_run = true
      end

      def log_after
        self.after_run = true
      end
    end

    stub_active_rel_class('MyRelClass') do
      from_class :FromClass
      to_class :ToClass
      type 'rel_class_type'

      property :score, type: Integer
      property :links
      property :default, default: 'default_value'
      property :should_be_nil
      validates :should_be_nil, inclusion: {in: [nil]}
      serialize :links
    end
  end

  let(:from_node) { FromClass.create }
  let(:to_node) { ToClass.create }

  describe 'from_class, to_class' do
    it 'spits back the current variable if no argument is given' do
      expect(MyRelClass.from_class).to eq :FromClass
      expect(MyRelClass.to_class).to eq :ToClass
    end

    it 'sets the value with the argument given' do
      expect(MyRelClass.from_class).not_to eq :Object
      expect(MyRelClass.from_class(:Object)).to eq :Object
      expect(MyRelClass.from_class).to eq :Object

      expect(MyRelClass.to_class).not_to eq :Object
      expect(MyRelClass.to_class(:Object)).to eq :Object
      expect(MyRelClass.to_class).to eq :Object
    end

    it 'validates that the class is ' do
      MyRelClass.to_class(:Object)

      expect { FromClass.create.other_others.to_a }.to raise_error ArgumentError, /Object is not an ActiveNode model/
    end
  end

  describe '#initialize' do
    context 'with string keys' do
      it do
        expect(MyRelClass.new('default' => 'new val').default).to eq 'new val'
      end
    end

    context 'with symbol keys' do
      it do
        expect(MyRelClass.new(default: 'new val').default).to eq 'new val'
      end
    end
  end

  describe '#increment, #increment!' do
    it 'increments an attribute' do
      rel = MyRelClass.create(from_node: from_node, to_node: to_node)
      rel.increment(:score)
      expect(rel.score).to eq(1)
      expect(rel.score_was).to eq(nil)

      rel.increment!(:score)
      expect(rel.score).to eq(2)
      expect(rel.score_was).to eq(2)
    end
  end

  describe '#concurrent_increment!' do
    it 'increments an attribute (concurrently)' do
      rel1 = MyRelClass.create(from_node: from_node, to_node: to_node)
      rel2 = MyRelClass.find(rel1.neo_id)
      rel1.concurrent_increment!(:score)
      expect(rel1.score).to eq(1)
      expect(rel1.score_was).to eq(1)
      rel2.concurrent_increment!(:score)
      expect(rel2.score).to eq(2)
      expect(rel1.reload.score).to eq(2)
    end
  end

  describe 'creation' do
    before(:each) do
      stub_active_rel_class('RelClassWithValidations') do
        from_class :FromClass
        to_class :ToClass
        type 'rel_class_type'

        property :score
        validates :score, presence: true
      end
    end

    shared_context 'three-argument ActiveRel create/create!' do |meth|
      # rubocop:disable Style/PredicateName
      def is_persisted_with_nodes(rel)
        expect(rel).to be_persisted
        expect(rel.from_node).to eq from_node
        expect(rel.to_node).to eq to_node
      end
      # rubocop:enable Style/PredicateName

      context 'node, node, hash' do
        it { is_persisted_with_nodes(MyRelClass.send(meth, from_node, to_node, {})) }
      end

      context 'node, node, nil' do
        it { is_persisted_with_nodes MyRelClass.send(meth, from_node, to_node, nil) }
      end

      context 'nil, nil, hash' do
        it { is_persisted_with_nodes MyRelClass.send(meth, nil, nil, from_node: from_node, to_node: to_node) }
      end

      context 'hash, nil, nil' do
        it { is_persisted_with_nodes MyRelClass.send(meth, {from_node: from_node, to_node: to_node}, nil, nil) }
      end
    end

    describe '#create' do
      it_behaves_like 'three-argument ActiveRel create/create!', :create
    end

    describe '#create!' do
      it 'raises an error on invalid params' do
        expect { RelClassWithValidations.create!(from_node: from_node, to_node: to_node) }.to raise_error Neo4j::ActiveRel::Persistence::RelInvalidError
      end

      it_behaves_like 'three-argument ActiveRel create/create!', :create!
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

    describe 'creates_unique' do
      after do
        MyRelClass.instance_variable_set(:@unique, false)
        [from_node, to_node].each(&:destroy)
      end


      it 'creates a unique relationship between to nodes' do
        expect(from_node.others.count).to eq 0
        MyRelClass.create(from_node: from_node, to_node: to_node)
        expect(from_node.others.count).to eq 1
        MyRelClass.creates_unique :none
        MyRelClass.create(from_node: from_node, to_node: to_node)
        expect(from_node.others.count).to eq 1
      end

      describe 'property filtering' do
        let(:nodes) { {from_node: from_node, to_node: to_node} }
        let(:first_props) { {score: 900} }
        let(:second_props) { {score: 1000} }
        let(:changed_props_create) { proc { MyRelClass.create(nodes.merge(second_props)) } }

        context 'with no arguments' do
          before { MyRelClass.creates_unique }

          it 'defaults to :none' do
            expect(Neo4j::Shared::FilteredHash).to receive(:new).with(instance_of(Hash), :none).and_call_original
            MyRelClass.create(nodes.merge(first_props))
          end
        end

        context 'with :none option' do
          before do
            MyRelClass.creates_unique(:none)
            MyRelClass.create(nodes.merge(first_props))
          end

          it 'does not create additional rels, even when properties change' do
            expect do
              changed_props_create.call
            end.not_to change { from_node.others.count }
          end
        end

        context 'with `:all` option' do
          before { MyRelClass.creates_unique :all }

          it 'creates additional rels when properties change' do
            expect { changed_props_create.call }.to change { from_node.others.count }
          end
        end

        context 'with {on: [keys]} option' do
          before do
            MyRelClass.creates_unique(on: :score)
            MyRelClass.create(nodes.merge(first_props))
          end

          context 'and a listed property changes' do
            it 'creates a new rel' do
              expect { changed_props_create.call }.to change { from_node.others.count }
            end
          end

          context 'and an unlisted property changes' do
            it 'does not create a new rel' do
              expect do
                MyRelClass.create(nodes.merge(default: 'some other value'))
              end.not_to change { from_node.others.count }
            end
          end
        end
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
      class ToClass; end

      context 'Array' do
        # stub_const does not behave with `it_is_expected_to_satisfy` so making it explicit for now...
        class OtherAcceptableClass
          include Neo4j::ActiveNode
        end

        it_is_expected_to_satisfy([:OtherAcceptableClass, :FromClass])
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
    let(:f1) { FromClass.create }
    let(:t1) { ToClass.create }
    let(:result) do
      Neo4j::Session.current.query('MATCH (start)-[r]-() WHERE ID(start) = {start_id} RETURN r.default AS value', start_id: f1.neo_id).to_a
    end

    context 'with a rel type requiring backticks' do
      before do
        MyRelClass.type 'LegacyClass#legacy_type'
      end

      it 'creates correctly' do
        expect { f1.others << t1 }.to change { f1.reload.others.count }.by(1)
      end
    end

    context 'with rel created from node' do
      context 'successfully' do
        before { f1.others << t1 }
        after { f1.destroy && t1.destroy }

        it 'returns the activerel class' do
          expect(f1.others.rels.first).to be_a(MyRelClass)
        end

        it 'correctly interprets strings as class names' do
          t1.string_others << f1
          expect(t1.string_others.count).to eq 2
        end

        it 'should use the ActiveRel class' do
          expect(result[0].value).to eq('default_value')
        end
      end

      context 'unsuccessfully' do
        it 'raises an error, does not create' do
          expect { f1.others.create(t1, should_be_nil: 'not nil') }.to raise_error Neo4j::ActiveRel::Persistence::RelInvalidError
          expect(result).to be_empty
        end
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
    context 'with a single hash' do
      let(:new_rel) { MyRelClass.new(from_node: from_node, to_node: to_node) }

      it 'pulls :from_node and :to_node out of the hash' do
        expect(new_rel.from_node).to eq from_node
        expect(new_rel.to_node).to eq to_node
      end
    end

    context 'with three arguments' do
      let(:new_rel) { MyRelClass.new(from_node, to_node, props) }

      context 'and nil props' do
        let(:props) { nil }

        it 'sets the nodes' do
          expect(new_rel.from_node).to eq from_node
          expect(new_rel.to_node).to eq to_node
          expect(new_rel.score).to be_nil
        end
      end

      context 'and present props' do
        let(:props) { {score: 9000} }

        it 'sets the nodes and props' do
          expect(new_rel.from_node).to eq from_node
          expect(new_rel.to_node).to eq to_node
          expect(new_rel.score).to eq 9000
        end
      end
    end
  end

  describe '#inspect' do
    context 'with unset from_node/to_node' do
      let(:new_rel) { MyRelClass.new }

      it 'does not raise an error' do
        allow(new_rel).to receive(:from_node).and_return double('From double')
        allow(new_rel).to receive(:to_node).and_return double('To double')
        expect(new_rel.from_node).not_to receive(:loaded)
        expect(new_rel.to_node).not_to receive(:loaded)
        expect { new_rel.inspect }.not_to raise_error
      end

      context 'single from/to class' do
        it 'inserts the class names in String' do
          next if Neo4j::VERSION >= '6.0.0'
          expect(new_rel.inspect).to include('(FromClass)-[:rel_class_type]->(ToClass)')
        end
      end

      context 'array of from/to class' do
        before { MyRelClass.from_class([:FromClass, :ToClass]) }

        it 'joins with ||' do
          next if Neo4j::VERSION >= '6.0.0'
          expect(new_rel.inspect).to include('(FromClass || ToClass)-[:rel_class_type]->(ToClass)')
        end
      end
    end

    context 'with set, unloaded from_node/to_node' do
      let(:new_rel) { MyRelClass.create(from_node: from_node, to_node: to_node) }
      let(:reloaded) { Neo4j::Relationship.load(new_rel.id) }
      let(:inspected) { reloaded.inspect }

      # Neo4j Embedded always returns nodes with rels. This is only possible in Server mode.
      it 'notes the ids of the nodes' do
        next if Neo4j::VERSION >= '6.0.0'
        next if Neo4j::Session.current.db_type == :embedded_db
        [from_node.neo_id, to_node.neo_id].each do |id|
          expect(inspected).to include("(Node with neo_id #{id})")
        end
      end
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

  context 'with `ActionController::Parameters`' do
    let(:params) { action_controller_params('score' => 7) }
    let(:create_params) { params.merge(from_node: from_node, to_node: to_node) }
    let(:klass) { MyRelClass }
    subject { klass.new(from_node: from_node, to_node: to_node) }

    it_should_behave_like 'handles permitted parameters'
  end
end
