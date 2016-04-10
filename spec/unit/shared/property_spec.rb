describe Neo4j::Shared::Property do
  let(:clazz) { Class.new { include Neo4j::ActiveNode::Property } }

  describe ':property class method' do
    it 'raises an error when passing illegal properties' do
      Neo4j::Shared::DeclaredProperty::ILLEGAL_PROPS.push 'foo'
      expect { clazz.property :foo }.to raise_error(Neo4j::Shared::DeclaredProperty::IllegalPropertyError)
    end
  end

  describe '.undef_property' do
    before(:each) { clazz.property(:bar, options) }
    let(:options) { {} }
    let(:remove!) { clazz.undef_property(:bar) }

    describe 'methods' do
      it 'are removed' do
        expect { remove! }.to change { [:bar, :bar=].all? { |meth| clazz.method_defined?(meth) } }.from(true).to(false)
      end
    end

    describe 'property definition' do
      it 'is removed' do
        expect { remove! }.to change { clazz.declared_properties[:bar] }.to(nil)
      end
    end

    describe 'schema' do
      before do
        allow_any_instance_of(Neo4j::Shared::DeclaredProperty).to receive(:index_or_constraint?).and_return true
        allow(clazz.class).to receive(:index)
      end

      context 'exact index' do
        it 'is removed' do
          expect(clazz).to receive(:drop_index)
          remove!
        end
      end

      context 'unique constraint' do
        it 'is removed' do
          expect_any_instance_of(Neo4j::Shared::DeclaredProperty).to receive(:constraint?).and_return(true)
          expect(clazz).to receive(:drop_constraint)
          remove!
        end
      end
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
      it 'does not change the attributes type' do
        expect(clazz.attributes[:created_at][:type]).to eq(Time)
        expect(clazz.attributes[:updated_at][:type]).to eq(Time)
      end
    end
  end

  describe '#typecasting' do
    context 'with custom typecaster' do
      let(:typecaster) do
        Class.new do
          def to_ruby(value)
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

    # TODO: Is this still necessary past 7.0, post ActiveAttr removal?
    it 'sets underlying typecaster to ObjectTypecaster' do
      expect(clazz.attributes[:range][:typecaster]).to eq(Neo4j::Shared::TypeConverters::ObjectConverter)
    end

    it 'adds new converter' do
      expect(Neo4j::Shared::TypeConverters::CONVERTERS[Range]).to eq(converter)
    end

    it 'returns object of a proper type' do
      instance.range = range
      expect(instance.range).to be_a(Range)
    end

    it 'uses type converter to serialize node' do
      instance.range = range
      expect(instance.class.declared_properties.convert_properties_to(instance, :db, instance.props)[:range]).to eq(range.to_s)
    end

    it 'uses type converter to deserialize node' do
      instance.range = range.to_s
      expect(instance.class.declared_properties.convert_properties_to(instance, :ruby, instance.props)[:range]).to eq(range)
    end
  end

  describe Neo4j::ActiveNode do
    before(:each) do
      # This serializer adds a text when the data is saved on the db,
      # and removes it when deserializing
      stub_const('MySerializer', Class.new do
        def initialize(text)
          @text = text
        end

        def converted?(value)
          value.is_a?(db_type)
        end

        def db_type
          String
        end

        def convert_type
          Symbol
        end

        def to_ruby(value)
          value.gsub(@text, '').to_sym if value
        end

        def to_db(value)
          "#{value}#{@text}" if value
        end
      end)

      stub_active_node_class('MyData') do
        property :polite_string
        property :happy_string

        serialize :polite_string, MySerializer.new(', sir.')
        serialize :happy_string, MySerializer.new(' :)')
      end
    end

    it 'serializes correctly' do
      data = MyData.new
      data.polite_string = :hello
      data.happy_string = :hello
      data.save!
      expect(MyData.as(:d).pluck('d.polite_string, d.happy_string')).to eq([['hello, sir.', 'hello :)']])
    end
  end
end
