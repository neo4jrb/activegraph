describe 'custom type conversion' do
  before(:each) do
    clear_model_memory_caches

    stub_named_class('RangeConverter') do
      class << self
        def primitive_type
          String
        end

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
        alias_method :call, :to_ruby
      end

      include Neo4j::Shared::Typecaster
    end

    stub_active_node_class('RangeConvertPerson') do
      property :my_range, type: Range
    end
  end

  it 'registers' do
    expect(Neo4j::Shared::TypeConverters::CONVERTERS).to have_key(Range)
  end

  before { RangeConvertPerson.create!(my_range: 1..30) }
  let(:r) { RangeConvertPerson.first }

  it 'uses for persistence' do
    expect(r.my_range).to be_a(Range)
  end

  it 'uses for QueryProxy #where' do
    expect(RangeConvertPerson.where(my_range: 1..30).first).to eq r
  end
end
