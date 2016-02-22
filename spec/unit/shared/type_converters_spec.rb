module Neo4j::Shared
  describe TypeConverters do
    subject(:model) { properties_class.new }

    let :properties_class do
      Class.new do
        include Neo4j::Shared::TypeConverters
      end
    end

    describe '#typecast_attribute' do
      it 'raises an ArgumentError when a nil type is given' do
        expect { model.typecast_attribute(nil, 'foo') }.to raise_error(ArgumentError, /A typecaster must be given/)
      end

      it 'raises an ArgumentError when the given typecaster argument does not respond to #call' do
        expect { model.typecast_attribute(Object.new, 'foo') }.to raise_error(ArgumentError, /A typecaster must be given/)
      end

      it 'returns the original value when the value is nil' do
        expect(properties_class.new.typecast_attribute(double(to_ruby: 1), nil)).to be_nil
      end
    end

    describe '#typecaster_for' do
      it 'returns BigDecimalTypecaster for BigDecimal' do
        expect(model.typecaster_for(BigDecimal)).to eq TypeConverters::BigDecimalConverter
      end

      it 'returns BooleanTypecaster for Boolean' do
        expect(model.typecaster_for(Neo4j::Shared::Boolean)).to eq TypeConverters::BooleanConverter
      end

      it 'returns DateTypecaster for Date' do
        expect(model.typecaster_for(Date)).to eq TypeConverters::DateConverter
      end

      it 'returns DateTypecaster for Date' do
        expect(model.typecaster_for(DateTime)).to eq TypeConverters::DateTimeConverter
      end

      it 'returns FloatTypecaster for Float' do
        expect(model.typecaster_for(Float)).to eq TypeConverters::FloatConverter
      end

      it 'returns IntegerTypecaster for Integer' do
        expect(model.typecaster_for(Integer)).to eq TypeConverters::IntegerConverter
      end

      it 'returns StringTypecaster for String' do
        expect(model.typecaster_for(String)).to eq TypeConverters::StringConverter
      end

      it 'returns ObjectTypecaster for Object' do
        expect(model.typecaster_for(Object)).to eq TypeConverters::ObjectConverter
      end
    end
  end
end
