describe Neo4j::ActiveNode::IdProperty do
  before do
    Neo4j::Config.delete(:id_property)
    Neo4j::Config.delete(:id_property_type)
    Neo4j::Config.delete(:id_property_type_value)
    clear_model_memory_caches
  end

  describe 'abnormal cases' do
    describe 'id_property' do
      it 'raise for id_property :something, :bla' do
        expect do
          stub_active_node_class('Unique') do
            id_property :something, :bla
          end
        end.to raise_error(/Expected a Hash/)
      end

      it 'raise for id_property :something, bla: 42' do
        expect do
          stub_active_node_class('Unique') do
            id_property :something, bla: 42
          end
        end.to raise_error(/Illegal value/)
      end
    end
  end


  describe 'when no id_property' do
    before do
      delete_db
      delete_schema
      stub_active_node_class('Clazz') do
        property :name
      end
    end

    it 'uses the neo_id as id after save' do
      allow(SecureRandom).to receive(:uuid) { 'secure123' }
      node = Clazz.new
      expect(node.id).to eq(nil)
      node.save!
      expect(node.id).to eq('secure123')
    end

    it 'can find by id uses the neo_id' do
      node = Clazz.create!
      node.name = 'kalle'
      expect(Clazz.find_by_id(node.id)).to eq(node)
    end

    it 'returns :id as primary_key' do
      expect(Clazz.primary_key).to eq :uuid
    end

    it 'responds false to id_property' do
      expect(Clazz.id_property?).to be_truthy
    end

    describe 'when having a configuration' do
      before do
        let_context(:id_property) { :the_id }
        let_context(:id_property_type) { :auto }
        let_context(:id_property_type_value) { :uuid }
        stub_active_node_class('Clazz')
      end

      it 'will set the id_property' do
        node = Clazz.new
        expect(node).to respond_to(:the_id)
        expect(Clazz.mapped_label.indexes).to match_array [[:the_id]]
      end
    end
  end

  describe 'when having neo_id configuration' do
    before do
      before_session do
        Neo4j::Config[:id_property] = :neo_id
        stub_active_node_class('NeoIdTest')
      end
    end

    it 'it will find node by neo_id' do
      node = NeoIdTest.create
      expect(NeoIdTest.where(id: node).first).to eq(node)
    end
  end

  describe 'id_property :myid' do
    before do
      delete_db
      delete_schema
      stub_active_node_class('Clazz') do
        id_property :myid
      end
    end

    it 'has an index' do
      Clazz.ensure_id_property_info!
      expect(Clazz.mapped_label.indexes).to match array_including([[:myid]])
    end

    describe 'property myid' do
      it 'is not defined when before save ' do
        node = Clazz.new
        expect(node.myid).to be_nil
      end

      it 'can be set' do
        node = Clazz.new
        node.myid = '42'
        expect(node.myid).to eq('42')
      end

      it 'can be saved after set' do
        node = Clazz.new
        node.myid = '42'
        node.save!
        expect(node.myid).to eq('42')
      end

      it 'is same as id' do
        node = Clazz.new
        node.myid = '42'
        expect(node.id).to be_nil
      end

      it 'is returned by primary_key' do
        expect(Clazz.primary_key).to eq :myid
      end

      it 'makes the class respond true to id_property?' do
        expect(Clazz.id_property?).to be_truthy
      end

      it 'removes any previously declared properties' do
        Clazz.id_property :my_property, auto: :uuid
        Clazz.id_property :another_property, auto: :uuid
        node = Clazz.create
        expect(node.respond_to?(:uuid)).to be_falsey
        expect(node.respond_to?(:my_property)).to be_falsey
      end
    end

    describe 'find_by_id' do
      it 'finds it if it exists' do
        Clazz.create(myid: 'a')
        node_b = Clazz.create(myid: 'b')
        Clazz.create(myid: 'c')
        found = Clazz.find_by_id('b')
        expect(found).to eq(node_b)
      end

      it 'does not find it if it does not exist' do
        Clazz.create(myid: 'd')

        found = Clazz.find_by_id('something else')
        expect(found).to be_nil
      end
    end

    describe 'find_by_neo_id' do
      it 'loads by the neo id' do
        node1 = Clazz.create
        found = Clazz.find_by_neo_id(node1.neo_id)
        expect(found).to eq node1
      end
    end

    describe 'order' do
      it 'should order by myid' do
        nodes = Array.new(3) { |i| Clazz.create myid: i }

        expect(Clazz.order(id: :desc).to_a).to eq(nodes.reverse)
      end
    end
  end


  describe 'id_property :my_id, on: :foobar' do
    before do
      delete_db
      delete_schema
      stub_active_node_class('Clazz') do
        id_property :my_id, on: :foobar

        def foobar
          'some id'
        end
      end
    end

    it 'has an index' do
      Clazz.ensure_id_property_info!

      expect(Clazz.mapped_label.indexes).to eq([[:my_id]])
    end

    it 'throws exception if the same uuid is generated when saving node' do
      Clazz.default_property :my_id do
        'same uuid'
      end
      Clazz.create
      expect { Clazz.create }.to raise_error(/Node \d+ already exists with label/)
    end

    describe 'property my_id' do
      it 'is not defined when before save ' do
        node = Clazz.new
        expect(node.my_id).to be_nil
      end

      it "is set to foobar's return value after save" do
        node = Clazz.new
        node.save
        expect(node.my_id).to eq('some id')
      end

      it 'is same as id' do
        node = Clazz.new
        expect(node.id).to be_nil
        node.save
        expect(node.id).to eq(node.my_id)
      end
    end


    describe 'find_by_id' do
      it 'finds it if it exists' do
        node = Clazz.create!
        expect(Clazz.find_by_id(node.my_id)).to eq(node)
      end
    end
  end

  describe 'constraint setting' do
    before do
      stub_active_node_class('Clazz')
    end

    context 'constraint: false' do
      it 'does not create a constraint' do
        Clazz.id_property :my_uuid, auto: :uuid, constraint: false
        expect(Clazz).not_to receive(:constraint)
        Clazz.ensure_id_property_info!
      end
    end

    context 'constraint: true' do
      it 'does create a constraint' do
        Clazz.id_property :my_uuid, auto: :uuid, constraint: true
        expect(Clazz).to receive(:constraint)
        Clazz.ensure_id_property_info!
      end
    end

    context 'constraint: nil' do
      it 'creates a constraint' do
        Clazz.id_property :my_uuid, auto: :uuid
        expect(Clazz).to receive(:constraint)
        Clazz.ensure_id_property_info!
      end
    end
  end

  describe 'redefining the default property' do
    context 'without a constraint' do
      before do
        delete_db
        delete_schema
        stub_active_node_class('NoConstraintClass') do
          id_property :uuid, auto: :uuid, constraint: false
          index :uuid
        end
      end

      it 'prevents the setting of default uuid constraint' do
        expect(NoConstraintClass.constraint?(:uuid)).to be_falsy
        expect(NoConstraintClass.mapped_label.index?(:uuid)).to be_truthy
      end

      describe 'inheritence' do
        before do
          stub_named_class('ConstraintSubclass', NoConstraintClass) do
            id_property :uuid, auto: :uuid, constraint: true
          end
        end

        it 'overrides the parent' do
          expect(NoConstraintClass.constraint?(:uuid)).to be_falsy
          expect(NoConstraintClass.mapped_label.index?(:uuid)).to be_truthy

          expect(ConstraintSubclass.constraint?(:uuid)).to be_truthy
          expect(ConstraintSubclass.mapped_label.index?(:uuid)).to be_truthy
        end
      end
    end
  end

  describe 'id_property :my_uuid, auto: :uuid' do
    before do
      stub_active_node_class('Clazz') do
        id_property :my_uuid, auto: :uuid
      end
    end

    it 'has an index' do
      Clazz.ensure_id_property_info!

      expect(Clazz.mapped_label.indexes).to eq([[:my_uuid]])
    end

    it 'throws exception if the same uuid is generated when saving node' do
      Clazz.default_property :my_uuid do
        'same uuid'
      end
      Clazz.create
      expect { Clazz.create }.to raise_error(/Node \d+ already exists with label/)
    end

    describe 'property my_uuid' do
      it 'is not defined when before save ' do
        node = Clazz.new
        expect(node.my_uuid).to be_nil
      end

      it 'is is set when saving ' do
        node = Clazz.new
        node.save
        expect(node.my_uuid).to_not be_empty
      end

      it 'is same as id' do
        node = Clazz.new
        expect(node.id).to be_nil
        node.save
        expect(node.id).to eq(node.my_uuid)
      end
    end

    describe 'find_by_id' do
      it 'finds it if it exists' do
        Clazz.create
        node = Clazz.create
        Clazz.create

        found = Clazz.find_by_id(node.my_uuid)
        expect(found).to eq(node)
      end

      it 'does not find it if it does not exist' do
        Clazz.create

        found = Clazz.find_by_id('something else')
        expect(found).to be_nil
      end
    end
  end

  describe 'id_property :neo_id' do
    before do
      before_session do
        stub_const('NeoIdTest', UniqueClass.create do
          include Neo4j::ActiveNode
          id_property :neo_id
        end)
      end
    end

    it 'has an index' do
      expect(NeoIdTest.mapped_label.indexes[:property_keys]).to be_empty
    end

    describe 'property id' do
      it 'is is set when saving ' do
        node = NeoIdTest.new
        expect { node.save }.to change { node.id.present? }.from(false).to(true)
      end

      it 'is same as neo_id' do
        node = NeoIdTest.create
        expect(node.id).to eq(node.neo_id)
      end
    end

    describe 'find_by_id' do
      it 'finds it if it exists' do
        NeoIdTest.create
        node = NeoIdTest.create
        NeoIdTest.create

        found = NeoIdTest.find_by_id(node.id)
        expect(found).to eq(node)
      end

      it 'does not find it if it does not exist' do
        found = NeoIdTest.find_by_id(NeoIdTest.create.id + 1)
        expect(found).to be_nil
      end
    end

    describe 'find_by_ids' do
      it 'finds them if they exist' do
        NeoIdTest.create
        nodes = Array.new(3) { NeoIdTest.create }
        NeoIdTest.create

        expect(NeoIdTest.find_by_ids(nodes.map(&:id))).to eq(nodes)
      end

      it 'does not find it if it does not exist' do
        found = NeoIdTest.find_by_ids([NeoIdTest.create.id + 1])
        expect(found).to be_empty
      end
    end

    describe 'where' do
      it 'should use neo_id' do
        NeoIdTest.create
        node = NeoIdTest.create
        NeoIdTest.create

        found = NeoIdTest.where(id: node.id).first
        expect(found).to eq(node)
      end

      it 'should find if id is a string' do
        node = NeoIdTest.create
        expect(NeoIdTest.where(id: node.id.to_s).first).to eq(node)
      end

      it 'should find with array' do
        NeoIdTest.create
        nodes = Array.new(3) { NeoIdTest.create }
        NeoIdTest.create

        expect(NeoIdTest.where(id: nodes)).to eq(nodes)
      end
    end

    describe 'where_not' do
      it 'should find complement' do
        node = NeoIdTest.create
        excluded = NeoIdTest.create
        expect(NeoIdTest.where_not(id: excluded)).to eq([node])
      end
    end

    describe 'order' do
      it 'should order by neo_id' do
        nodes = Array.new(3) { NeoIdTest.create }
        expect(NeoIdTest.order(id: :desc).to_a).to eq(nodes.reverse)
      end
    end
  end

  describe 'inheritance' do
    before(:all) do
      before_session do
        module IdProp
          Teacher = UniqueClass.create do
            include Neo4j::ActiveNode
            id_property :my_id, on: :my_method

            def my_method
              'an id'
            end
          end

          class Substitute < Teacher; end

          Vehicle = UniqueClass.create do
            include Neo4j::ActiveNode
            id_property :my_id, auto: :uuid
          end

          class Car < Vehicle; end

          Fruit = UniqueClass.create do
            include Neo4j::ActiveNode

            id_property :my_id
          end

          class Apple < Fruit; end

          Sport = UniqueClass.create do
            include Neo4j::ActiveNode

            id_property :neo_id
          end

          class Skiing < Sport; end
        end
      end
    end

    after(:all) { [IdProp::Teacher, IdProp::Car, IdProp::Apple, IdProp::Sport, IdProp::Skiing].each(&:delete_all) }

    it 'inherits the base id_property' do
      expect(IdProp::Substitute.create.my_id).to eq 'an id'
    end

    it 'works with auto uuid' do
      expect(IdProp::Car.create.my_id).not_to be_nil
    end

    it 'works without conf specified' do
      expect(IdProp::Apple.create.my_id).not_to be_nil
    end

    it 'works with neo_id' do
      node = IdProp::Skiing.create
      expect(node.id).not_to be_nil
      expect(node.id).to eq(node.neo_id)
    end

    context 'when a session is not started' do
      it 'waits until the session is loaded, then sets id property' do
        Neo4j::Session.current.close

        stub_active_node_class('IdProp::Executive') do
          id_property :my_id, on: :my_method

          def my_method
            'an id'
          end
        end

        stub_named_class('IdProp::CEO', IdProp::Executive)
      end

      it 'subclass inherits the primary_key' do
        expect(IdProp::CEO.primary_key).to eq(:my_id)
      end
    end
  end
end
