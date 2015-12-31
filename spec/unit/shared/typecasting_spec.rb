module Neo4j::Shared
  describe Typecasting do
    subject(:model) { model_class.new }

    let :model_class do
      Class.new do
        include Typecasting
      end
    end

    describe '#typecast_attribute' do
      it 'raises an ArgumentError when a nil type is given' do
        expect { model.typecast_attribute(nil, 'foo') }.to raise_error(ArgumentError, 'a typecaster must be given')
      end

      it 'raises an ArgumentError when the given typecaster argument does not respond to #call' do
        expect { model.typecast_attribute(Object.new, 'foo') }.to raise_error(ArgumentError, 'a typecaster must be given')
      end

      it 'returns the original value when the value is nil' do
        model_class.new.typecast_attribute(double(call: 1), nil).should be_nil
      end
    end

    describe '#typecaster_for' do
      it 'returns BigDecimalTypecaster for BigDecimal' do
        model.typecaster_for(BigDecimal).should be_a_kind_of Typecasting::BigDecimalTypecaster
      end

      it 'returns BooleanTypecaster for Boolean' do
        model.typecaster_for(Typecasting::Boolean).should be_a_kind_of Typecasting::BooleanTypecaster
      end

      it 'returns DateTypecaster for Date' do
        model.typecaster_for(Date).should be_a_kind_of Typecasting::DateTypecaster
      end

      it 'returns DateTypecaster for Date' do
        model.typecaster_for(DateTime).should be_a_kind_of Typecasting::DateTimeTypecaster
      end

      it 'returns FloatTypecaster for Float' do
        model.typecaster_for(Float).should be_a_kind_of Typecasting::FloatTypecaster
      end

      it 'returns IntegerTypecaster for Integer' do
        model.typecaster_for(Integer).should be_a_kind_of Typecasting::IntegerTypecaster
      end

      it 'returns StringTypecaster for String' do
        model.typecaster_for(String).should be_a_kind_of Typecasting::StringTypecaster
      end

      it 'returns ObjectTypecaster for Object' do
        model.typecaster_for(Object).should be_a_kind_of Typecasting::ObjectTypecaster
      end
    end
  end
end
