require 'spec_helper'

describe Neo4j::Shared::Property do 
  let(:clazz) { Class.new { include Neo4j::Shared::Property } }

  describe ':property class method' do
    it 'raises an error when passing illegal properties' do
      Neo4j::Shared::Property::ILLEGAL_PROPS.push 'foo'
      expect{clazz.property :foo}.to raise_error(Neo4j::Shared::Property::IllegalPropertyError)
    end
  end

  describe '.undef_property' do
    before(:each) do
      clazz.property :bar

      expect(clazz).to receive(:undef_constraint_or_index)
      clazz.undef_property :bar
    end
    it 'removes methods' do
      clazz.method_defined?(:bar).should be false
      clazz.method_defined?(:bar=).should be false
      clazz.method_defined?(:bar?).should be false
    end
  end

  describe 'types for timestamps' do
    context 'when type is undefined' do
      before do
        clazz.property :created_at
        clazz.property :updated_at
      end

      it 'sets type to DateTime' do
        expect(clazz.attributes[:created_at][:type]).to eq(DateTime)
        expect(clazz.attributes[:updated_at][:type]).to eq(DateTime)
      end
    end

    context 'when type is defined' do
      before do
        clazz.property :created_at, type: Date
        clazz.property :updated_at, type: Date
      end

      it 'does not change type' do
        expect(clazz.attributes[:created_at][:type]).to eq(Date)
        expect(clazz.attributes[:updated_at][:type]).to eq(Date)
      end
    end

    context 'for Time type' do
      before do
        clazz.property :created_at, type: Time
        clazz.property :updated_at, type: Time
      end

      it 'changes type to DateTime' do
        expect(clazz.attributes[:created_at][:type]).to eq(DateTime)
        expect(clazz.attributes[:updated_at][:type]).to eq(DateTime)
      end
    end
  end

  describe '#typecasting' do
    context 'with custom typecaster' do
      let(:typecaster) do
        Class.new do
          def call(value)
            value.to_s.upcase
          end
        end
      end

      let(:instance) { clazz.new }

      before do
        allow(clazz).to receive(:extract_association_attributes!)
        clazz.property :some_property, typecaster: typecaster.new
      end

      it 'uses custom typecaster' do
        instance.some_property = 'test'
        expect(instance.some_property).to eq('TEST')
      end
    end
  end
end
