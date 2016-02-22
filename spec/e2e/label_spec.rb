describe 'Neo4j::ActiveNode' do
  let(:clazz) do
    UniqueClass.create do
      include Neo4j::ActiveNode
    end
  end

  let(:label_name) do
    clazz.to_s.to_sym
  end

  describe 'labels' do
    context 'with _persisted_obj.labels present' do
      it 'returns the label of the class' do
        expect(clazz.create.labels).to eq([label_name])
      end
    end
  end

  describe 'property' do
    describe 'property :age, index: :exact' do
      let(:clazz) do
        UniqueClass.create do
          include Neo4j::ActiveNode
        end
      end

      it 'creates an index' do
        expect(clazz).to receive(:index).with(:age)
        clazz.property :age, index: :exact
      end
    end

    describe 'property :name, constraint: :unique' do
      it 'delegates to the Schema Operation class' do
        clazz = UniqueClass.create { include Neo4j::ActiveNode }
        expect_any_instance_of(Neo4j::Schema::UniqueConstraintOperation).to receive(:create!).and_call_original
        clazz.property :name, constraint: :unique
      end
    end

    describe 'property :age, index: :exact, constraint: :unique' do
      let(:clazz) do
        UniqueClass.create do
          include Neo4j::ActiveNode
        end
      end

      it 'raises an error, cannot set both index and constraint' do
        expect { clazz.property :age, index: :exact, constraint: :unique }
          .to raise_error(Neo4j::InvalidPropertyOptionsError)
      end
    end

    describe 'property :age, constraint: :unique' do
      let(:clazz) do
        UniqueClass.create do
          include Neo4j::ActiveNode
        end
      end

      it 'creates a constraint but not an index' do # creating an constraint does also automatically create an index
        expect(clazz).not_to receive(:index).with(:age, index: :exact)
        expect(clazz).to receive(:constraint).with(:age, type: :unique)
        clazz.property :age, constraint: :unique
      end
    end
  end


  describe 'constraint' do
    let(:clazz_with_constraint) do
      UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
        property :age
        constraint :name, type: :unique
      end
    end

    describe 'constraint :name, type: :unique' do
      it 'can not create two nodes with unique properties' do
        clazz_with_constraint.create(name: 'foobar')
        expect { clazz_with_constraint.create(name: 'foobar') }.to raise_error StandardError, /already exists/
      end

      it 'can create two nodes with different properties' do
        clazz_with_constraint.create(name: 'foobar1')
        expect { clazz_with_constraint.create(name: 'foobar2') }.to_not raise_error
      end
    end

    context 'with existing constraint' do
      context 'when trying to set an index' do
        before { clazz_with_constraint }

        it 'raises an error, does not create the index' do
          expect_any_instance_of(Neo4j::Schema::ExactIndexOperation).not_to receive(:create!)
          expect { clazz_with_constraint.index :name }.to raise_error Neo4j::InvalidPropertyOptionsError
        end
      end
    end

    context 'with existing exact index' do
      # before { clazz_with_constraint.index(:foo) }
      before do
        Neo4j::Schema::UniqueConstraintOperation.new(clazz_with_constraint.mapped_label_name, :name).drop!
        Neo4j::Schema::ExactIndexOperation.new(clazz_with_constraint.mapped_label_name, :name).create!
      end

      it 'drops the index before making the constraint' do
        expect_any_instance_of(Neo4j::Schema::ExactIndexOperation).to receive(:drop!).and_call_original
        clazz_with_constraint.constraint(:name, type: :unique)
      end
    end
  end

  describe 'index' do
    let(:clazz) do
      UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
        index :name
      end
    end

    let(:other_class) do
      UniqueClass.create do
        include Neo4j::ActiveNode
      end
    end

    it 'creates an index' do
      expect(clazz.mapped_label.indexes).to eq(property_keys: [[:name], [:uuid]])
    end

    it 'does not create index on other classes' do
      expect(clazz.mapped_label.indexes).to eq(property_keys: [[:name], [:uuid]])
      expect(other_class.mapped_label.indexes).to eq(property_keys: [[:uuid]])
    end

    context 'when set' do
      context 'and trying to also set a constraint' do
        before { clazz }

        it 'raises an error, does not modify the schema' do
          expect_any_instance_of(Neo4j::Schema::UniqueConstraintOperation).not_to receive(:create!)
          expect { clazz.constraint :name, type: :unique }.to raise_error Neo4j::InvalidPropertyOptionsError
        end
      end
    end

    describe 'when inherited' do
      it 'has an index on both base and subclass' do
        class Foo1
          include Neo4j::ActiveNode
          property :name, index: :exact
        end
        class Foo2 < Foo1
        end
        expect(Foo1.mapped_label.indexes).to eq(property_keys: [[:name], [:uuid]])
        expect(Foo2.mapped_label.indexes).to eq(property_keys: [[:name], [:uuid]])
      end
    end

    context 'with existing unique constraint' do
      before do
        Neo4j::Schema::ExactIndexOperation.new(clazz.mapped_label_name, :name).drop!
        Neo4j::Schema::UniqueConstraintOperation.new(clazz.mapped_label_name, :name, type: :unique).create!
      end

      it 'drops the constraint before creating the index' do
        expect do
          clazz.index(:name)
        end.to change { Neo4j::Label.constraint?(clazz.mapped_label_name, :name) }.from(true).to(false)
      end
    end
  end

  describe 'index?' do
    let(:clazz) do
      UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
        index :name
      end
    end

    it 'indicates whether a property is indexed' do
      expect(clazz.index?(:name)).to be_truthy
      expect(clazz.index?(:foo)).to be_falsey
    end
  end

  describe 'add_label' do
    it 'can add one label' do
      node = clazz.create
      node.add_label(:foo)
      expect(node.labels).to match_array([label_name, :foo])
    end

    it 'can add two label' do
      node = clazz.create
      node.add_label(:foo, :bar)
      expect(node.labels).to match_array([label_name, :foo, :bar])
    end
  end


  describe 'remove_label' do
    it 'can remove one label' do
      node = clazz.create
      node.add_label(:foo)
      node.remove_label(:foo)
      expect(node.labels).to match_array([label_name])
    end

    it 'can add two label' do
      node = clazz.create
      node.add_label(:foo, :bar, :baaz)
      node.remove_label(:foo, :baaz)
      expect(node.labels).to match_array([label_name, :bar])
    end
  end

  describe 'setting association values via initialize' do
    let(:clazz) do
      UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
        has_one :out, :foo, type: nil
      end
    end

    it 'indicates whether a property is indexed' do
      stub_const('::Foo', Class.new { include Neo4j::ActiveNode })

      o = clazz.new(name: 'Jim', foo: 2)

      expect(o.name).to eq('Jim')
      expect do
        expect(o.foo).to be_nil
      end.to raise_error(Neo4j::RecordNotFound)

      o.save!

      expect(o.name).to eq('Jim')
      expect do
        expect(o.foo).to be_nil
      end.to raise_error(Neo4j::RecordNotFound)
    end
  end

  describe '.find' do
    let(:clazz) do
      UniqueClass.create do
        include Neo4j::ActiveNode
      end
    end

    let(:object1) { clazz.create }
    let(:object2) { clazz.create }

    describe 'finding individual records' do
      it 'by id' do
        expect(clazz.find(object1.id)).to eq(object1)
        found = clazz.find(object1.id)
        expect(found).to be_a(clazz)
      end

      it 'by object' do
        expect(clazz.find(object1)).to eq(object1)
      end

      context 'with no results' do
        it 'raises an error' do
          expect { clazz.find(8_675_309) }.to raise_error { Neo4j::RecordNotFound }
        end
      end
    end

    describe 'finding multiple records' do
      it 'by id' do
        expect(clazz.find([object1.id, object2.id]).to_set).to eq([object1, object2].to_set)
      end

      it 'by object' do
        expect(clazz.find([object1, object2]).to_set).to eq([object1, object2].to_set)
      end

      context 'with no results' do
        it 'raises an error' do
          expect { clazz.find[8_675_309] }.to raise_error { Neo4j::RecordNotFound }
        end
      end
    end
  end
end
