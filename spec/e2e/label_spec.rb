describe 'Neo4j::ActiveNode' do
  before do
    clear_model_memory_caches
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
      before { Clazz.property :name, constraint: :unique }
      it_behaves_like 'raises schema error including', :constraint, :Clazz, :name
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
      it_behaves_like 'raises schema error including', :constraint, :ClazzWithConstraint, :name
    end

    context 'when trying to set an index' do
      before { ClazzWithConstraint.index :name }

      it_behaves_like 'raises schema error including', :constraint, :ClazzWithConstraint, :name
    end
  end

  describe 'model schema definitions' do
    let_config(:id_property, nil)
    let_config(:id_property_type, nil)
    let_config(:id_property_type_value, nil)
    let(:properties) { [] }
    let(:constraints) { [] }
    let(:indexes) { [] }
    let(:with_constraint) { true }
    let(:subclass_properties) { [] }
    let(:subclass_constraints) { [] }
    let(:subclass_indexes) { [] }
    let(:subclass_with_constraint) { true }

    def define_active_node_class(name, model_properties, model_constraints, model_indexes, with_constraint = true)
      stub_active_node_class(name.to_s, with_constraint) do
        model_properties.each { |args| property(*Array(args)) }
        model_constraints.each { |args| constraint(*Array(args)) }
        model_indexes.each { |args| index(*Array(args)) }
      end
    end

    let!(:clazz) do
      define_active_node_class(:Clazz, properties, constraints, indexes, with_constraint)
    end

    let!(:other_class) do
      define_active_node_class(:SubClazz, subclass_properties, subclass_constraints, subclass_indexes, subclass_with_constraint)
    end

    it_behaves_like 'does not raise schema error', :Clazz

    let_context properties: [:name] do
      it_behaves_like 'does not raise schema error', :Clazz

      let_context constraints: [:name] do
        it_behaves_like 'raises schema error including', :constraint, :Clazz, :name

        let_context indexes: [:name] do
          it_behaves_like 'raises schema error including', :constraint, :Clazz, :name
          it_behaves_like 'raises schema error not including', :index, :Clazz, :name
          it_behaves_like 'raises schema error not including', :constraint, :Clazz, :uuid
          it_behaves_like 'raises schema error not including', :constraint, :SubClazz

          context 'name constraint created' do
            before { create_constraint(:Clazz, :name, type: :unique) }

            it_behaves_like 'does not raise schema error', :Clazz
            it_behaves_like 'does not log id_property constraint option false warning', :Clazz
            it_behaves_like 'does not log schema option warning', :constraint, :Clazz, :uuid
            it_behaves_like 'logs schema option warning', :constraint, :Clazz, :name
          end

          let_context with_constraint: false do
            it_behaves_like 'raises schema error including', :constraint, :Clazz, :name
            it_behaves_like 'raises schema error including', :constraint, :Clazz, :uuid
            it_behaves_like 'raises schema error not including', :constraint, :SubClazz
          end
        end
      end
      let_context indexes: [:name] do
        it_behaves_like 'raises schema error including', :index, :Clazz, :name
      end
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

      stub_active_node_class('Foo')
    end

    it 'indicates whether a property is indexed' do
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
