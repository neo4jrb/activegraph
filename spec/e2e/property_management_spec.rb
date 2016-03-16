describe 'declared property classes' do
  describe Neo4j::Shared::DeclaredProperty do
    before do
      clazz = Class.new do
        def primitive_type; end
      end

      stub_const('MyTypeCaster', clazz)
    end

    let(:clazz) { Neo4j::Shared::DeclaredProperty }

    describe Neo4j::Shared::DeclaredProperty do
      let(:prop) { clazz.new(:my_prop) }

      context 'illegal property names' do
        it 'raises an error' do
          expect { clazz.new(:from_node) }.to raise_error { Neo4j::Shared::DeclaredProperty::IllegalPropertyError }
        end
      end

      describe 'options' do
        let(:prop) { clazz.new(:my_prop, type: String, typecaster: MyTypeCaster, default: 'foo') }

        it 'controls method responses' do
          expect(prop.type).to eq String
          expect(prop.typecaster).to eq MyTypeCaster
          expect(prop.default_value).to eq 'foo'
        end
      end

      describe 'magic properties' do
        let(:created) { clazz.new(:created_at) }
        let(:updated) { clazz.new(:updated_at) }

        it 'automatically sets type for created_at and updated_at if unset' do
          expect(created.type).to be_nil
          expect(updated.type).to be_nil
          [created, updated].each(&:register)

          expect(created.type).to eq DateTime
          expect(updated.type).to eq DateTime
        end
      end

      describe '#index?, #index!, #unindex!' do
        it 'returns whether a property has been indexed' do
          expect(prop.index?).to eq false
          expect { prop.index! }.to change { prop.index? }.from(false).to(true)
          expect { prop.unindex! }.to change { prop.index? }.to(false)
        end
      end

      describe '#constraint?, #constraint!, #unconstraint!' do
        it 'returns constraint status, changes' do
          expect(prop.constraint?).to eq false
          expect { prop.constraint! }.to change { prop.constraint? }.to(true)
          expect { prop.unconstraint! }.to change { prop.constraint? }.to(false)
        end
      end
    end
  end

  describe Neo4j::Shared::DeclaredProperties do
    before do
      clazz = Class.new do
        include Neo4j::ActiveNode
        property :foo
        property :bar, type: String, default: 'foo'
        property :baz, type: Neo4j::Shared::Boolean, default: false
        validates :baz, inclusion: {in: [true, false]}
      end

      stub_const('MyModel', clazz)
    end

    let(:model) { MyModel }
    let(:dpm)   { MyModel.declared_properties }

    it 'is included on each class' do
      expect(model.declared_properties).to be_a(Neo4j::Shared::DeclaredProperties)
    end

    it 'has a convenience method on each instance' do
      inst = model.new
      expect(inst.declared_properties.object_id).to eq model.declared_properties.object_id
    end

    it 'delegates #each, #each_key, #each_value to #registered_properties' do
      dpm.each do |name, property|
        expect(dpm.registered_properties).to have_key(name)
        expect(dpm.registered_properties[name]).to eq property
      end
      expect(dpm.each_key.to_a).to eq(dpm.registered_properties.keys)
      expect(dpm.each_value.to_a).to eq(dpm.registered_properties.values)
    end

    it 'contains information about each declared property' do
      [:foo, :bar].each do |key|
        expect(dpm.registered_properties[key]).to be_a(Neo4j::Shared::DeclaredProperty)
        expect(dpm[key]).to be_a(Neo4j::Shared::DeclaredProperty)
        expect(dpm.property?(key)).to be_truthy
      end

      expect(dpm.property?(:buzz)).to eq false
    end

    it 'keeps a default hash of nil values for use in initial object wrapping' do
      expect(dpm.attributes_nil_hash).to have_key('foo')
      expect(dpm.attributes_nil_hash).to have_key('bar')
    end

    describe 'inheritance' do
      before do
        clazz = Class.new do
          include Neo4j::ActiveNode
          property :foo
          property :bar, type: String, default: 'foo'
        end

        stub_const('MyModel', clazz)

        clazz = Class.new(MyModel) do
          include Neo4j::ActiveNode
        end

        stub_const('MyInheritedClass', clazz)
      end

      let(:dpm) { MyModel.declared_properties }
      let(:inherited_dpm) { MyInheritedClass.declared_properties }

      it 'applies the ancestor\'s props' do
        dpm.registered_properties.each_key do |k|
          expect(inherited_dpm.registered_properties).to have_key(k)
        end
      end
    end

    # This mimics the behavior of active_attr's default property values
    describe 'default property values' do
      let(:node) { MyModel.new }

      it 'sets the default property val at init' do
        expect(node.bar).to eq 'foo'
      end

      context 'with type: Boolean and default: false' do
        subject { node.baz }
        it { is_expected.to eq false }

        context 'model from new with attributes' do
          let(:node) { MyModel.new }
          it { is_expected.to eq false }
        end

        context 'model from new with attributes' do
          let(:node) { MyModel.new(foo: 'foo') }
          it { is_expected.to eq false }
        end

        context 'model from create' do
          let(:node) { MyModel.create }
          it { is_expected.to eq false }
        end

        context 'model from create with attributes' do
          let(:node) { MyModel.create(foo: 'foo') }
          it { is_expected.to eq false }
        end
      end


      context 'with value not default, not updated' do
        before do
          node.bar = 'bar'
          node.save
          node.reload
          node.foo = 'foo'
          node.save
          node.reload
        end

        it 'does not reset' do
          expect(node.bar).to eq 'bar'
        end
      end

      context 'with changed values' do
        before do
          node.bar = value
          node.baz = true
          node.save!
          node.reload
        end

        context 'on reload when prop was changed to nil' do
          let(:value) { nil }

          it 'resets nil default properties on reload' do
            expect(node.bar).to eq 'foo'
          end
        end

        context 'on reload when prop was set' do
          let(:value) { 'bar' }

          it 'does not reset to default' do
            expect(node.bar).to eq 'bar'
            expect(node.baz).to eq true
          end
        end
      end
    end
  end
end
