require 'spec_helper'

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
    end
  end

  describe Neo4j::Shared::DeclaredPropertyManager do
    before do
      clazz = Class.new do
        include Neo4j::ActiveNode
        property :foo
        property :bar, type: String, default: 'foo'
        property :baz, type: ActiveAttr::Typecasting::Boolean, default: false
      end

      stub_const('MyModel', clazz)
    end

    let(:model) { MyModel }
    let(:dpm)   { MyModel.declared_property_manager }

    it 'is included on each class' do
      expect(model.declared_property_manager).to be_a(Neo4j::Shared::DeclaredPropertyManager)
    end

    it 'has a convenience method on each instance' do
      inst = model.new
      expect(inst.declared_property_manager.object_id).to eq model.declared_property_manager.object_id
    end

    it 'contains information about each declared property' do
      [:foo, :bar].each do |key|
        expect(dpm.registered_properties[key]).to be_a(Neo4j::Shared::DeclaredProperty)
      end
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

      let(:dpm) { MyModel.declared_property_manager }
      let(:inherited_dpm) { MyInheritedClass.declared_property_manager }

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
        it 'sets as expected' do
          expect(node.baz).to eq false
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
          node.baz = bool_value
          node.save
          node.reload
        end

        context 'on reload when prop was changed to nil' do
          let(:value) { nil }
          let(:bool_value) { nil }

          it 'resets nil default properties on reload' do
            expect(node.bar).to eq 'foo'
            expect(node.baz).to eq false
          end
        end

        context 'on reload when prop was set' do
          let(:value) { 'bar' }
          let(:bool_value) { true }

          it 'does not reset to default' do
            expect(node.bar).to eq 'bar'
            expect(node.baz).to eq true
          end
        end
      end
    end
  end
end
