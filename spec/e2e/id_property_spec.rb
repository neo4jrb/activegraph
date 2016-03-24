describe Neo4j::ActiveNode::IdProperty do
  before do
    Neo4j::Config.delete(:id_property)
    Neo4j::Config.delete(:id_property_type)
    Neo4j::Config.delete(:id_property_type_value)
  end

  describe 'abnormal cases' do
    describe 'id_property' do
      it 'raise for id_property :something, :bla' do
        expect do
          stub_const('Unique', UniqueClass.create do
            include Neo4j::ActiveNode
            id_property :something, :bla
          end)
        end.to raise_error(/Expected a Hash/)
      end

      it 'raise for id_property :something, bla: 42' do
        expect do
          stub_const('Unique', UniqueClass.create do
            include Neo4j::ActiveNode
            id_property :something, bla: 42
          end)
        end.to raise_error(/Illegal value/)
      end
    end
  end


  describe 'when no id_property' do
    before do
      stub_const('Clazz', UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
      end)
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
        before_session do
          Neo4j::Config[:id_property] = :the_id
          Neo4j::Config[:id_property_type] = :auto
          Neo4j::Config[:id_property_type_value] = :uuid
          stub_const('Clazz', Class.new do
            include Neo4j::ActiveNode
          end)
        end
      end

      it 'will set the id_property after a session has been created' do
        node = Clazz.new
        expect(node).to respond_to(:the_id)
        expect(Clazz.mapped_label.indexes[:property_keys].sort).to eq([[:the_id], [:uuid]])
      end
    end
  end

  describe 'id_property :myid' do
    before do
      before_session do
        stub_const('Clazz', UniqueClass.create do
          include Neo4j::ActiveNode
          id_property :myid
        end)
      end
    end

    it 'has an index' do
      expect(Clazz.mapped_label.indexes[:property_keys]).to eq([[:myid]])
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
  end


  describe 'id_property :my_id, on: :foobar' do
    before do
      before_session do
        stub_const('Clazz', UniqueClass.create do
          include Neo4j::ActiveNode
          id_property :my_id, on: :foobar

          def foobar
            'some id'
          end
        end)
      end
    end

    it 'has an index' do
      expect(Clazz.mapped_label.indexes[:property_keys]).to eq([[:my_id]])
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
      stub_const('Clazz', UniqueClass.create do
        include Neo4j::ActiveNode
      end)
    end

    context 'constraint: false' do
      it 'does not create a constraint' do
        expect(Clazz).not_to receive(:constraint)
        Clazz.id_property :my_uuid, auto: :uuid, constraint: false
      end
    end

    context 'constraint: true' do
      it 'does create a constraint' do
        expect(Clazz).to receive(:constraint)
        Clazz.id_property :my_uuid, auto: :uuid, constraint: true
      end
    end

    context 'constraint: nil' do
      it 'creates a constraint' do
        expect(Clazz).to receive(:constraint)
        Clazz.id_property :my_uuid, auto: :uuid
      end
    end
  end

  describe 'redefining the default property' do
    before { Neo4j::Session.current.close if Neo4j::Session.current }

    context 'without a constraint' do
      before do
        stub_const('NoConstraintClass', Class.new do
                                          include Neo4j::ActiveNode
                                          id_property :uuid, auto: :uuid, constraint: false
                                          index :uuid
                                        end)
      end

      it 'prevents the setting of default uuid constraint' do
        expect(NoConstraintClass).not_to receive(:constraint)
        create_session
        expect(Neo4j::Label.index?(NoConstraintClass.mapped_label_name, :uuid)).to be_truthy
      end

      describe 'inheritence' do
        before do
          stub_const('ConstraintSubclass', Class.new(NoConstraintClass) do
                                             include Neo4j::ActiveNode
                                             id_property :uuid, auto: :uuid, constraint: true
                                           end)
        end

        it 'overrides the parent' do
          expect(ConstraintSubclass).to receive(:constraint)
          create_session
        end
      end
    end
  end

  describe 'id_property :my_uuid, auto: :uuid' do
    before do
      Neo4j::Session.current.close if Neo4j::Session.current
      stub_const('Clazz', UniqueClass.create do
        include Neo4j::ActiveNode
        id_property :my_uuid, auto: :uuid
      end)
      create_session
    end

    it 'has an index' do
      expect(Clazz.mapped_label.indexes[:property_keys]).to eq([[:my_uuid]])
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

  describe 'inheritance' do
    before(:all) do
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
      end
    end

    after(:all) { [IdProp::Teacher, IdProp::Car, IdProp::Apple].each(&:delete_all) }

    it 'inherits the base id_property' do
      expect(IdProp::Substitute.create.my_id).to eq 'an id'
    end

    it 'works with auto uuid' do
      expect(IdProp::Car.create.my_id).not_to be_nil
    end

    it 'works without conf specified' do
      expect(IdProp::Apple.create.my_id).not_to be_nil
    end

    context 'when a session is not started' do
      it 'waits until the session is loaded, then sets id property' do
        Neo4j::Session.current.close

        module IdProp
          class Executive
            include Neo4j::ActiveNode
            id_property :my_id, on: :my_method

            def my_method
              'an id'
            end
          end

          class CEO < Executive; end
        end

        expect(IdProp::CEO.primary_key).to be_nil
        create_session
        expect(IdProp::CEO.primary_key).not_to be_nil
      end
    end
  end
end
