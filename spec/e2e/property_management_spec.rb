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
      expect(dpm.attributes_nil_hash).to eq('foo' => nil, 'bar' => nil)
    end
  end
end
