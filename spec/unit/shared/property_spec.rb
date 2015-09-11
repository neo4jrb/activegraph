require 'spec_helper'

describe Neo4j::Shared::Property do
  let(:clazz) { Class.new { include Neo4j::Shared::Property } }

  describe ':property class method' do
    it 'raises an error when passing illegal properties' do
      Neo4j::Shared::DeclaredProperty::ILLEGAL_PROPS.push 'foo'
      expect { clazz.property :foo }.to raise_error(Neo4j::Shared::DeclaredProperty::IllegalPropertyError)
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
    context 'when type is undefined inline' do
      before do
        clazz.property :created_at
        clazz.property :updated_at
      end

      it 'defaults to DateTime' do
        expect(clazz.attributes[:created_at][:type]).to eq(DateTime)
        expect(clazz.attributes[:updated_at][:type]).to eq(DateTime)
      end

      context '...and specified in config' do
        before do
          Neo4j::Config[:timestamp_type] = Integer
          clazz.property :created_at
          clazz.property :updated_at
        end

        it 'uses type set in config' do
          expect(clazz.attributes[:created_at][:type]).to eq(Integer)
          expect(clazz.attributes[:updated_at][:type]).to eq(Integer)
        end
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

      # ActiveAttr does not know what to do with Time, so it is stored as Int.
      it 'tells ActiveAttr it is an Integer' do
        expect(clazz.attributes[:created_at][:type]).to eq(Integer)
        expect(clazz.attributes[:updated_at][:type]).to eq(Integer)
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

  describe '#custom type converter' do
    let(:converter) do
      Class.new do
        class << self
          def convert_type
            Range
          end

          def to_db(value)
            value.to_s
          end

          def to_ruby(value)
            ends = value.to_s.split('..').map { |d| Integer(d) }
            ends[0]..ends[1]
          end
        end
      end
    end

    let(:clazz)     { Class.new { include Neo4j::ActiveNode } }
    let(:instance)  { clazz.new }
    let(:range)     { 1..3 }

    before do
      clazz.property :range, serializer: converter
    end

    it 'sets active_attr typecaster to ObjectTypecaster' do
      expect(clazz.attributes[:range][:typecaster]).to be_a(ActiveAttr::Typecasting::ObjectTypecaster)
    end

    it 'adds new converter' do
      expect(Neo4j::Shared::TypeConverters.converters[Range]).to eq(converter)
    end

    it 'returns object of a proper type' do
      instance.range = range
      expect(instance.range).to be_a(Range)
    end

    it 'uses type converter to serialize node' do
      instance.range = range
      expect(instance.class.declared_property_manager.convert_properties_to(instance, :db, instance.props)[:range]).to eq(range.to_s)
    end

    it 'uses type converter to deserialize node' do
      instance.range = range.to_s
      expect(instance.class.declared_property_manager.convert_properties_to(instance, :ruby, instance.props)[:range]).to eq(range)
    end
  end
end
