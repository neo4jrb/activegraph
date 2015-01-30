require 'spec_helper'

describe 'custom type conversion' do
  class RangeConverter
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

  class RangeConvertPerson
    include Neo4j::ActiveNode
    property :my_range, type: Range
  end

  it 'registers the typecaster' do
    expect(Neo4j::Shared::TypeConverters.converters).to have_key(Range)
  end

  it 'uses the custom typecaster' do
    r = RangeConvertPerson.new
    r.my_range = 1..30
    r.save
    r.reload
    expect(r.my_range).to be_a(Range)
  end
end
