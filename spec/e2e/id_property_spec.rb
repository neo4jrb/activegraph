describe Neo4j::ActiveNode::IdProperty do
  before(:all) do
    Neo4j::Config.delete(:id_property)
    Neo4j::Config.delete(:id_property_type)
    Neo4j::Config.delete(:id_property_type_value)
  end

  before do
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
    let!(:clazz) do
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
      let_config(:id_property, :the_id)
      let_config(:id_property_type, :auto)
      let_config(:id_property_type_value, :uuid)

      let!(:clazz) do
        stub_active_node_class('Clazz')
      end

      it 'will set the id_property' do
        node = Clazz.new
        expect(node).to respond_to(:the_id)
        expect(Clazz.mapped_label.indexes).to match_array [a_hash_including(label: :Clazz, properties: [:the_id])]
      end
    end
  end

  describe 'when having neo_id configuration' do
    let_config(:id_property, :neo_id)

    before do
      stub_active_node_class('NeoIdTest')
    end

    it 'it will find node by neo_id' do
      node = NeoIdTest.create
      expect(NeoIdTest.where(id: node).first).to eq(node)
    end
  end

  describe 'id_property :myid' do
    before do
      stub_active_node_class('Clazz') do
        id_property :myid
      end
    end

    it 'has an index' do
      Clazz.ensure_id_property_info!
      expect(Clazz.mapped_label.indexes).to match array_including([a_hash_including(label: :Clazz, properties: [:myid])])
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

      context 'id_property defined twice' do
        before do
          Neo4j::ModelSchema::MODEL_CONSTRAINTS.clear

          Clazz.id_property :my_property, auto: :uuid
          Clazz.id_property :another_property, auto: :uuid
          Clazz.ensure_id_property_info!
        end

        it 'removes any previously declared properties' do
          begin
            node = Clazz.create
          rescue Neo4j::DeprecatedSchemaDefinitionError
            nil
          end
          expect(node.respond_to?(:uuid)).to be_falsey
          expect(node.respond_to?(:my_property)).to be_falsey
        end

        it_behaves_like 'raises schema error not including', :constraint, :Clazz, :uuid
        it_behaves_like 'raises schema error not including', :constraint, :Clazz, :myid
        it_behaves_like 'raises schema error not including', :constraint, :Clazz, :my_property
        it_behaves_like 'raises schema error including', :constraint, :Clazz, :another_property
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


  EXISTS_REGEXP = /Node.\d+\)? already exists with label/

  describe 'id_property :my_id, on: :foobar' do
    before do
      stub_active_node_class('Clazz') do
        id_property :my_id, on: :foobar

        def foobar
          'some id'
        end
      end
    end

    it 'has an index' do
      Clazz.ensure_id_property_info!

      expect(Clazz.mapped_label.indexes).to match array_including([a_hash_including(label: :Clazz, properties: [:my_id])])
    end

    it 'throws exception if the same uuid is generated when saving node' do
      Clazz.default_property :my_id do
        'same uuid'
      end
      Clazz.create
      expect { Clazz.create }.to raise_error(EXISTS_REGEXP)
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
    let(:id_property_name) {}
    let(:id_property_options) { {} }

    let(:subclass_id_property_name) {}
    let(:subclass_id_property_options) { {} }

    before do
      delete_schema

      property_name = id_property_name
      property_options = id_property_options
      stub_active_node_class('Clazz', false) do
        id_property property_name, property_options.merge(auto: :uuid) if property_name
      end
      property_name = subclass_id_property_name
      property_options = subclass_id_property_options
      stub_named_class('SubClazz', Clazz) do
        id_property property_name, property_options.merge(auto: :uuid) if property_name
      end
      Clazz.ensure_id_property_info!
      SubClazz.ensure_id_property_info!
      Neo4j::ModelSchema.reload_models_data!
    end

    it_behaves_like 'raises schema error including', :constraint, :Clazz, :uuid
    it_behaves_like 'raises schema error not including', :constraint, :SubClazz

    let_context id_property_name: :my_uuid do
      let_context id_property_options: {constraint: false} do
        it_behaves_like 'logs id_property constraint option false warning', :Clazz
        it_behaves_like 'does not log id_property constraint option false warning', :SubClazz

        let_context subclass_id_property_name: :other_uuid do
          it_behaves_like 'logs id_property constraint option false warning', :Clazz
          it_behaves_like 'does not log id_property constraint option false warning', :SubClazz

          let_context subclass_id_property_options: {constraint: false} do
            it_behaves_like 'logs id_property constraint option false warning', :Clazz
            it_behaves_like 'logs id_property constraint option false warning', :SubClazz
          end

          let_context subclass_id_property_options: {constraint: true} do
            it_behaves_like 'logs id_property constraint option false warning', :Clazz
            it_behaves_like 'does not log id_property constraint option false warning', :SubClazz

            it_behaves_like 'raises schema error including', :constraint, :Clazz, :my_uuid
            it_behaves_like 'raises schema error including', :constraint, :SubClazz, :other_uuid
          end
        end

        let_context subclass_id_property_name: :my_uuid do
          it_behaves_like 'logs id_property constraint option false warning', :Clazz
          it_behaves_like 'does not log id_property constraint option false warning', :SubClazz

          let_context subclass_id_property_options: {constraint: false} do
            it_behaves_like 'logs id_property constraint option false warning', :Clazz
            it_behaves_like 'logs id_property constraint option false warning', :SubClazz
          end
        end
      end

      let_context id_property_options: {constraint: true} do
        it_behaves_like 'raises schema error including', :constraint, :Clazz, :my_uuid
        it_behaves_like 'raises schema error not including', :constraint, :SubClazz

        let_context subclass_id_property_options: {constraint: true} do
          let_context subclass_id_property_name: :other_uuid do
            it_behaves_like 'raises schema error including', :constraint, :Clazz, :my_uuid
            it_behaves_like 'raises schema error including', :constraint, :SubClazz, :other_uuid
          end

          let_context subclass_id_property_name: :my_uuid do
            it_behaves_like 'raises schema error including', :constraint, :Clazz, :my_uuid
            it_behaves_like 'raises schema error including', :constraint, :SubClazz, :my_uuid
          end
        end
      end

      let_context id_property_options: {constraint: nil} do
        it_behaves_like 'raises schema error including', :constraint, :Clazz, :my_uuid
        it_behaves_like 'raises schema error not including', :constraint, :SubClazz

        let_context subclass_id_property_options: {constraint: nil} do
          let_context subclass_id_property_name: :other_uuid do
            it_behaves_like 'raises schema error including', :constraint, :Clazz, :my_uuid
            it_behaves_like 'raises schema error including', :constraint, :SubClazz, :other_uuid
          end

          let_context subclass_id_property_name: :my_uuid do
            it_behaves_like 'raises schema error including', :constraint, :Clazz, :my_uuid
            it_behaves_like 'raises schema error including', :constraint, :SubClazz, :my_uuid
          end
        end

        let_context subclass_id_property_options: {constraint: true} do
          let_context subclass_id_property_name: :other_uuid do
            it_behaves_like 'raises schema error including', :constraint, :Clazz, :my_uuid
            it_behaves_like 'raises schema error including', :constraint, :SubClazz, :other_uuid
          end

          let_context subclass_id_property_name: :my_uuid do
            it_behaves_like 'raises schema error including', :constraint, :Clazz, :my_uuid
            it_behaves_like 'raises schema error including', :constraint, :SubClazz, :my_uuid
          end
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

      expect(Clazz.mapped_label.indexes).to match array_including([a_hash_including(label: :Clazz, properties: [:my_uuid])])
    end

    it 'throws exception if the same uuid is generated when saving node' do
      Clazz.default_property :my_uuid do
        'same uuid'
      end
      Clazz.create
      expect { Clazz.create }.to raise_error(EXISTS_REGEXP)
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
      stub_active_node_class('NeoIdTest', false) do
        id_property :neo_id
      end
    end

    it 'has an index' do
      NeoIdTest.ensure_id_property_info!

      expect(NeoIdTest.mapped_label.indexes).to be_empty
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

        expect(NeoIdTest.find_by_ids(nodes.map(&:id))).to match_array(nodes)
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

        expect(NeoIdTest.where(id: nodes)).to match_array(nodes)
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
        # ascending neo_ids during insertion cannot be guaranteed anymore in community version'
        nodes = Array.new(3) { NeoIdTest.create }.sort_by!(&:id)
        expect(NeoIdTest.order(id: :desc).to_a).to eq(nodes.reverse)
      end
    end
  end

  describe 'inheritance' do
    before do
      stub_active_node_class('Teacher') do
        id_property :my_id, on: :my_method

        def my_method
          'an id'
        end
      end

      stub_named_class('Substitute', Teacher)

      stub_active_node_class('Vehicle') do
        id_property :my_id, auto: :uuid
      end

      stub_named_class('Car', Vehicle)

      stub_active_node_class('Fruit') do
        id_property :my_id
      end

      stub_named_class('Apple', Fruit)

      stub_active_node_class('Sport') do
        id_property :neo_id
      end

      stub_named_class('Skiing', Sport)
    end

    it 'inherits the base id_property' do
      expect(Substitute.create.my_id).to eq 'an id'
    end

    it 'works with auto uuid' do
      expect(Car.create.my_id).not_to be_nil
    end

    it 'works without conf specified' do
      expect(Apple.create.my_id).not_to be_nil
    end

    it 'works with neo_id' do
      node = Skiing.create
      expect(node.id).not_to be_nil
      expect(node.id).to eq(node.neo_id)
    end

    context 'when a session is not started' do
      before do
        stub_active_node_class('Executive') do
          id_property :my_id, on: :my_method

          def my_method
            'an id'
          end
        end

        stub_named_class('CEO', Executive)
      end

      it 'subclass inherits the primary_key' do
        expect(CEO.primary_key).to eq(:my_id)
      end
    end
  end
end
