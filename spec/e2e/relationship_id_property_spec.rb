describe ActiveGraph::Node::IdProperty do
  before(:context) do
    ActiveGraph::Config.delete(:id_property)
    ActiveGraph::Config.delete(:id_property_type)
    ActiveGraph::Config.delete(:id_property_type_value)
  end

  before do
    clear_model_memory_caches
  end

  let!(:nclass) do
    stub_node_class('Single')
  end

  let(:nnode) { Single.create! }

  describe 'abnormal cases' do
    describe 'id_property' do
      it 'raise for id_property :something, :bla' do
        expect do
          stub_relationship_class('Unique') do
            id_property :something, :bla
          end
        end.to raise_error(/Expected a Hash/)
      end

      it 'raise for id_property :something, bla: 42' do
        expect do
          stub_relationship_class('Unique') do
            id_property :something, bla: 42
          end
        end.to raise_error(/Illegal value/)
      end
    end
  end

  describe 'when no id_property' do
    let!(:clazz) do
      stub_relationship_class('Clazz') do
        property :name
        from_class :Single
        to_class :Single
      end
    end

    it 'uses the uuid as id after save' do
      allow(SecureRandom).to receive(:uuid) { 'secure123' }
      node = Clazz.new(nnode, nnode)
      expect(node.id).to eq(nil)
      node.save!
      expect(node.id).to eq('secure123')
    end

    it 'can find by id uses the id_property' do
      rel = Clazz.create!(nnode, nnode)
      rel.name = 'kalle'
      expect(Clazz.find_by_id(rel.id)).to eq(rel)
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
        stub_relationship_class('Clazz')
      end

      it 'will set the id_property' do
        node = Clazz.new(nnode, nnode)
        expect(node).to respond_to(:the_id)
        expect(Clazz.mapped_element.indexes).to match_array [a_hash_including(label: :CLAZZ, properties: [:the_id])]
      end
    end
  end

  describe 'id_property :myid' do
    before do
      stub_relationship_class('Clazz') do
        id_property :myid
        from_class :Single
        to_class :Single
      end
    end

    it 'has an index' do
      Clazz.ensure_id_property_info!
      expect(Clazz.mapped_element.indexes).to match array_including([a_hash_including(label: :CLAZZ, properties: [:myid])])
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
        node = Clazz.new(nnode, nnode)
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
          ActiveGraph::ModelSchema::MODEL_CONSTRAINTS.clear

          Clazz.id_property :my_property, auto: :uuid
          Clazz.id_property :another_property, auto: :uuid
          Clazz.ensure_id_property_info!
        end

        it 'removes any previously declared properties' do
          begin
            node = Clazz.create(nnode, nnode)
          rescue ActiveGraph::DeprecatedSchemaDefinitionError
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
        Clazz.create(nnode, nnode, myid: 'a')
        rel_b = Clazz.create(nnode, nnode, myid: 'b')
        Clazz.create(nnode, nnode, myid: 'c')
        found = Clazz.where(myid: 'b').first
        expect(found).to eq(rel_b)
      end

      it 'does not find it if it does not exist' do
        Clazz.create(nnode, nnode, myid: 'd')

        expect(Clazz.find_by_id('something else')).to be_nil
      end
    end

    describe 'find_by_neo_id' do
      it 'loads by the neo id' do
        rel1 = Clazz.create(nnode, nnode)
        found = Clazz.find_by_neo_id(rel1.neo_id)
        expect(found).to eq rel1
      end
    end
  end

  def raise_constraint_error
    raise_error(Neo4j::Driver::Exceptions::ClientException) do |error|
      expect(error.code).to eq 'Neo.ClientError.Schema.ConstraintValidationFailed'
    end
  end

  describe 'id_property :my_id, on: :foobar' do
    before do
      stub_relationship_class('Clazz') do
        id_property :my_id, on: :foobar
        from_class :Single
        to_class :Single

        def foobar
          'some id'
        end
      end
    end

    it 'has an index' do
      Clazz.ensure_id_property_info!

      expect(Clazz.mapped_element.indexes).to match array_including([a_hash_including(label: :CLAZZ, properties: [:my_id])])
    end

    it 'throws exception if the same uuid is generated when saving node' do
      Clazz.default_property :my_id do
        'same uuid'
      end
      Clazz.create(nnode, nnode)
      expect { Clazz.create(nnode, nnode) }.to raise_constraint_error
    end

    describe 'property my_id' do
      it 'is not defined when before save ' do
        node = Clazz.new
        expect(node.my_id).to be_nil
      end

      it "is set to foobar's return value after save" do
        node = Clazz.new(nnode, nnode)
        node.save
        expect(node.my_id).to eq('some id')
      end

      it 'is same as id' do
        node = Clazz.new(nnode, nnode)
        expect(node.id).to be_nil
        node.save
        expect(node.id).to eq(node.my_id)
      end
    end

    describe 'find_by_id' do
      it 'finds it if it exists' do
        node = Clazz.create!(nnode, nnode)
        expect(Clazz.find_by_id(node.my_id)).to eq(node)
      end
    end
  end

  describe 'id_property :my_uuid, auto: :uuid' do
    before do
      stub_relationship_class('Clazz') do
        id_property :my_uuid, auto: :uuid
        from_class :Single
        to_class :Single
        type :Clazz
      end
    end

    it 'has an index' do
      Clazz.ensure_id_property_info!

      expect(Clazz.mapped_element.indexes).to match array_including([a_hash_including(label: :Clazz, properties: [:my_uuid])])
    end

    it 'throws exception if the same uuid is generated when saving node' do
      Clazz.default_property :my_uuid do
        'same uuid'
      end
      Clazz.create(nnode, nnode)
      expect { Clazz.create(nnode, nnode) }.to raise_constraint_error
    end

    describe 'property my_uuid' do
      it 'is not defined when before save ' do
        node = Clazz.new(nnode, nnode)
        expect(node.my_uuid).to be_nil
      end

      it 'is is set when saving ' do
        node = Clazz.new(nnode, nnode)
        node.save
        expect(node.my_uuid).to_not be_empty
      end

      it 'is same as id' do
        node = Clazz.new(nnode, nnode)
        expect(node.id).to be_nil
        node.save
        expect(node.id).to eq(node.my_uuid)
      end
    end

    describe 'find_by_id' do
      it 'finds it if it exists' do
        Clazz.create(nnode, nnode)
        node = Clazz.create(nnode, nnode)
        Clazz.create(nnode, nnode)

        found = Clazz.find_by_id(node.my_uuid)
        expect(found).to eq(node)
      end

      it 'does not find it if it does not exist' do
        Clazz.create(nnode, nnode)

        found = Clazz.find_by_id('something else')
        expect(found).to be_nil
      end
    end
  end
end
