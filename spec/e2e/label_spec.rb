describe 'Neo4j::ActiveNode' do
  before do
    clear_model_memory_caches
    delete_db
    delete_schema
  end

  let!(:clazz) do
    stub_active_node_class('Clazz')
  end

  let(:label_name) do
    Clazz.to_s.to_sym
  end

  describe 'labels' do
    context 'with _persisted_obj.labels present' do
      it 'returns the label of the class' do
        expect(Clazz.create.labels).to eq([label_name])
      end
    end
  end

  describe 'property' do
    describe 'property :age, index: :exact' do
      it 'creates an index' do
        expect(Clazz).to receive(:index).with(:age)
        Clazz.property :age, index: :exact
      end
    end

    describe 'property :name, constraint: :unique' do
      it 'delegates to the Schema Operation class' do
        Clazz = UniqueClass.create { include Neo4j::ActiveNode }
        Clazz.ensure_id_property_info!
        expect_any_instance_of(Neo4j::Schema::UniqueConstraintOperation).to receive(:create!).and_call_original
        Clazz.property :name, constraint: :unique
      end
    end

    describe 'property :age, index: :exact, constraint: :unique' do
      it 'raises an error, cannot set both index and constraint' do
        expect { Clazz.property :age, index: :exact, constraint: :unique }
          .to raise_error(Neo4j::InvalidPropertyOptionsError)
      end
    end

    describe 'property :age, constraint: :unique' do
      it 'creates a constraint but not an index' do # creating an constraint does also automatically create an index
        expect(Clazz).not_to receive(:index).with(:age, index: :exact)
        expect(Clazz).to receive(:constraint).with(:age, type: :unique)
        Clazz.property :age, constraint: :unique
      end
    end
  end


  describe 'constraint' do
    let!(:clazz_with_constraint) do
      stub_active_node_class('ClazzWithConstraint') do
        property :name
        property :age
        constraint :name, type: :unique
      end
    end

    describe 'constraint :name, type: :unique' do
      it 'can not create two nodes with unique properties' do
        ClazzWithConstraint.create(name: 'foobar')
        expect { ClazzWithConstraint.create(name: 'foobar') }.to raise_error StandardError, /already exists/
      end

      it 'can create two nodes with different properties' do
        ClazzWithConstraint.create(name: 'foobar1')
        expect { ClazzWithConstraint.create(name: 'foobar2') }.to_not raise_error
      end
    end

    context 'with existing constraint' do
      context 'when trying to set an index' do
        before { ClazzWithConstraint }

        it 'raises an error, does not create the index' do
          expect_any_instance_of(Neo4j::Schema::ExactIndexOperation).not_to receive(:create!)
          expect { ClazzWithConstraint.index :name }.to raise_error Neo4j::InvalidPropertyOptionsError
        end
      end
    end

    context 'with existing exact index' do
      before do
        Neo4j::Schema::UniqueConstraintOperation.new(ClazzWithConstraint.mapped_label, :name).drop!
        Neo4j::Schema::ExactIndexOperation.new(ClazzWithConstraint.mapped_label, :name).create!
      end

      it 'drops the index before making the constraint' do
        expect_any_instance_of(Neo4j::Schema::ExactIndexOperation).to receive(:drop!).and_call_original
        ClazzWithConstraint.constraint(:name, type: :unique)
      end
    end
  end

  describe 'index' do
    let!(:clazz) do
      stub_active_node_class('Clazz') do
        property :name
        index :name
      end
    end

    let!(:other_class) do
      stub_active_node_class('OtherClass')
    end

    it 'creates an index' do
      expect(Clazz.mapped_label.indexes).to eq([[:name], [:uuid]])
    end

    it 'does not create index on other classes' do
      Clazz.ensure_id_property_info!
      OtherClass.ensure_id_property_info!
      expect(Clazz.mapped_label.indexes).to eq([[:name], [:uuid]])
      expect(OtherClass.mapped_label.indexes).to eq([[:uuid]])
    end

    context 'when set' do
      context 'and trying to also set a constraint' do
        it 'raises an error, does not modify the schema' do
          expect_any_instance_of(Neo4j::Schema::UniqueConstraintOperation).not_to receive(:create!)
          expect { Clazz.constraint :name, type: :unique }.to raise_error Neo4j::InvalidPropertyOptionsError
        end
      end
    end

    describe 'when inherited' do
      it 'has an index on both base and subclass' do
        stub_active_node_class('Foo1') do
          property :name, index: :exact
        end
        stub_named_class('Foo2', Foo1)

        expect(Foo1.mapped_label.indexes).to eq([[:name], [:uuid]])
        expect(Foo2.mapped_label.indexes).to eq([])
      end

      it 'only puts index on subclass if defined there' do
        stub_active_node_class('Foo1')
        stub_named_class('Foo2', Foo1) do
          property :name, index: :exact
        end

        expect(Foo1.mapped_label.indexes).to eq([[:uuid]])
        expect(Foo2.mapped_label.indexes).to eq([[:name], [:uuid]])
      end
    end

    context 'with existing unique constraint' do
      before do
        Neo4j::Schema::ExactIndexOperation.new(Clazz.mapped_label, :name).drop!
        Neo4j::Schema::UniqueConstraintOperation.new(Clazz.mapped_label, :name, type: :unique).create!
      end

      it 'drops the constraint before creating the index' do
        expect do
          Clazz.index(:name)
        end.to change { Clazz.mapped_label.uniqueness_constraint?(:name) }.from(true).to(false)
      end
    end
  end

  describe 'index?' do
    let!(:clazz) do
      stub_active_node_class('Clazz') do
        property :name
        index :name
      end
    end

    it 'indicates whether a property is indexed' do
      expect(Clazz.index?(:name)).to be_truthy
      expect(Clazz.index?(:foo)).to be_falsey
    end
  end

  def labels_for(node)
    node.query_as(:n).with('labels(n) AS labels').unwind(label: :labels).pluck(:label).map(&:to_sym)
  end

  describe 'add_labels' do
    it 'can add one label' do
      node = Clazz.create
      node.add_labels(:foo)
      expect(node.labels).to match_array([label_name, :foo])
      expect(labels_for(node)).to match_array([label_name, :foo])
    end

    it 'can add two label' do
      node = Clazz.create
      node.add_labels(:foo, :bar)
      expect(node.labels).to match_array([label_name, :foo, :bar])
      expect(labels_for(node)).to match_array([label_name, :foo, :bar])
    end
  end


  describe 'remove_labels' do
    it 'can remove one label' do
      node = Clazz.create
      node.add_labels(:foo)
      node.remove_labels(:foo)
      expect(node.labels).to match_array([label_name])
      expect(labels_for(node)).to match_array([label_name])
    end

    it 'can add two label' do
      node = Clazz.create
      node.add_labels(:foo, :bar, :baaz)
      node.remove_labels(:foo, :baaz)
      expect(node.labels).to match_array([label_name, :bar])
      expect(labels_for(node)).to match_array([label_name, :bar])
    end
  end

  describe 'setting association values via initialize' do
    let!(:clazz) do
      stub_active_node_class('Clazz') do
        property :name
        has_one :out, :foo, type: nil
      end
    end

    it 'indicates whether a property is indexed' do
      stub_const('::Foo', Class.new { include Neo4j::ActiveNode })

      o = Clazz.new(name: 'Jim', foo: 2)

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
    let(:object1) { Clazz.create }
    let(:object2) { Clazz.create }

    describe 'finding individual records' do
      it 'by id' do
        expect(Clazz.find(object1.id)).to eq(object1)
        found = Clazz.find(object1.id)
        expect(found).to be_a(Clazz)
      end

      it 'by object' do
        expect(Clazz.find(object1)).to eq(object1)
      end

      context 'with no results' do
        it 'raises an error' do
          expect { Clazz.find(8_675_309) }.to raise_error { Neo4j::RecordNotFound }
        end
      end
    end

    describe 'finding multiple records' do
      it 'by id' do
        expect(Clazz.find([object1.id, object2.id]).to_set).to eq([object1, object2].to_set)
      end

      it 'by object' do
        expect(Clazz.find([object1, object2]).to_set).to eq([object1, object2].to_set)
      end

      context 'with no results' do
        it 'raises an error' do
          expect { Clazz.find[8_675_309] }.to raise_error { Neo4j::RecordNotFound }
        end
      end
    end
  end
end
