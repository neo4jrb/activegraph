require 'spec_helper'

describe Neo4j::Shared::TypeConverters do
  describe 'converters' do
    it 'has converters for DateTime' do
      Neo4j::Shared::TypeConverters.converters[DateTime].should eq(Neo4j::Shared::TypeConverters::DateTimeConverter)
    end

    it 'has converters for Time' do
      Neo4j::Shared::TypeConverters.converters[Time].should eq(Neo4j::Shared::TypeConverters::TimeConverter)
    end

    it 'has converters for Date' do
      Neo4j::Shared::TypeConverters.converters[Date].should eq(Neo4j::Shared::TypeConverters::DateConverter)
    end

    it 'has converters for JSON' do
      Neo4j::Shared::TypeConverters.converters[JSON].should eq(Neo4j::Shared::TypeConverters::JSONConverter)
    end

    it 'has converters for YAML' do
      Neo4j::Shared::TypeConverters.converters[Hash].should eq(Neo4j::Shared::TypeConverters::YAMLConverter)
    end
  end

  describe 'to_ruby' do
    it 'converts if there is a converter' do
      date_time = Time.utc(2011, 3, 2, 10, 0, 0).to_i
      converter_value = Neo4j::Shared::TypeConverters.to_other(:to_ruby, date_time, DateTime)
      converter_value.should be_a(DateTime)
      converter_value.year.should eq(2011)
      converter_value.month.should eq(3)
      converter_value.day.should eq(2)
      converter_value.hour.should eq(10)
    end

    it 'returns the same value if there is no converter' do
      Neo4j::Shared::TypeConverters.to_other(:to_ruby, 42, Integer).should eq(42)
    end
  end

  describe 'to_db' do
    it 'converts if there is a converter' do
      date_time = DateTime.civil(2011, 3, 4, 1, 2, 3, 0)
      converter_value = Neo4j::Shared::TypeConverters.to_other(:to_db, date_time, DateTime)
      converter_value.should be_a(Integer)
    end

    it 'returns the same value if there is no converter' do
      Neo4j::Shared::TypeConverters.to_other(:to_ruby, 42, Integer).should eq(42)
    end

    it 'returns the same value if it is already of the expected type' do
      timestamp = DateTime.now.to_i
      expect(Neo4j::Shared::TypeConverters.to_other(:to_db, timestamp, DateTime)).to eq timestamp
    end
  end

  describe 'Integer' do
    subject { Neo4j::Shared::TypeConverters::IntegerConverter }

    it 'translates from and to database' do
      db_value = subject.to_db('1')
      ruby_value = subject.to_ruby('1')
      [db_value, ruby_value].each do |i|
        expect(i).to be_a(Integer)
        expect(i).to eq 1
      end
    end
  end

  describe 'Float' do
    subject { Neo4j::Shared::TypeConverters::FloatConverter }

    it 'translates from and to database' do
      db_value = subject.to_db('1')
      ruby_value = subject.to_ruby('1')
      [db_value, ruby_value].each do |i|
        expect(i).to be_a(Float)
        expect(i).to eq 1.0
      end
    end
  end

  describe 'BigDecimal' do
    subject { Neo4j::Shared::TypeConverters::BigDecimalConverter }

    context 'from Rational' do
      let(:r) { Rational(1) }

      it 'translates' do
        expect(subject.to_db(r)).to be_a(BigDecimal)
        expect(subject.to_db(r)).to eq(BigDecimal.new('1.0'))
        expect(subject.to_db(r)).not_to eq(BigDecimal.new('1.1'))
      end
    end

    context 'from float' do
      let(:r) { 1.0 }

      it 'translates' do
        expect(subject.to_db(r)).to be_a(BigDecimal)
      end
    end

    context 'from String' do
      let(:r) { '1.0' }

      it 'translates' do
        expect(subject.to_db(r)).to be_a(BigDecimal)
      end
    end
  end

  describe 'String' do
    subject { Neo4j::Shared::TypeConverters::StringConverter }

    describe '#to_db and #to_ruby' do
      it 'calls to_s on the object' do
        expect(subject.to_db(1)).to eq '1'
        expect(subject.to_ruby(1)).to eq '1'
      end
    end
  end

  # These tests originally from ActiveAttr gem
  describe 'Boolean' do
    subject { Neo4j::Shared::TypeConverters::BooleanConverter }

    describe '#to_db' do
      it 'returns true for true' do
        subject.to_db(true).should equal true
      end

      it 'returns false for false' do
        subject.to_db(false).should equal false
      end

      it 'casts nil to false' do
        subject.to_db(nil).should equal false
      end

      it 'casts an Object to true' do
        subject.to_db(Object.new).should equal true
      end

      context 'when the value is a String' do
        it 'casts an empty String to false' do
          subject.to_db('').should equal false
        end

        it 'casts a non-empty String to true' do
          subject.to_db('abc').should equal true
        end

        {
          't' => true,
          'f' => false,
          'T' => true,
          'F' => false,
          # http://yaml.org/type/bool.html
          'y' => true,
          'Y' => true,
          'yes' => true,
          'Yes' => true,
          'YES' => true,
          'n' => false,
          'N' => false,
          'no' => false,
          'No' => false,
          'NO' => false,
          'true' => true,
          'True' => true,
          'TRUE' => true,
          'false' => false,
          'False' => false,
          'FALSE' => false,
          'on' => true,
          'On' => true,
          'ON' => true,
          'off' => false,
          'Off' => false,
          'OFF' => false
        }.each_pair do |value, result|
          it "casts #{value.inspect} to #{result.inspect}" do
            subject.to_db(value).should equal result
          end
        end
      end

      context 'when the value is Numeric' do
        it 'casts 0 to false' do
          subject.to_db(0).should equal false
        end

        it 'casts 1 to true' do
          subject.to_db(1).should equal true
        end

        it 'casts 0.0 to false' do
          subject.to_db(0.0).should equal false
        end

        it 'casts 0.1 to true' do
          subject.to_db(0.1).should equal true
        end

        it 'casts a zero BigDecimal to false' do
          subject.to_db(BigDecimal.new('0.0')).should equal false
        end

        it 'casts a non-zero BigDecimal to true' do
          subject.to_db(BigDecimal.new('0.1')).should equal true
        end

        it 'casts -1 to true' do
          subject.to_db(-1).should equal true
        end

        it 'casts -0.0 to false' do
          subject.to_db(-0.0).should equal false
        end

        it 'casts -0.1 to true' do
          subject.to_db(-0.1).should equal true
        end

        it 'casts a negative zero BigDecimal to false' do
          subject.to_db(BigDecimal.new('-0.0')).should equal false
        end

        it 'casts a negative BigDecimal to true' do
          subject.to_db(BigDecimal.new('-0.1')).should equal true
        end
      end

      context 'when the value is the String version of a Numeric' do
        it "casts '0' to false" do
          subject.to_db('0').should equal false
        end

        it "casts '1' to true" do
          subject.to_db('1').should equal true
        end

        it "casts '0.0' to false" do
          subject.to_db('0.0').should equal false
        end

        it "casts '0.1' to true" do
          subject.to_db('0.1').should equal true
        end

        it "casts '-1' to true" do
          subject.to_db('-1').should equal true
        end

        it "casts '-0.0' to false" do
          subject.to_db('-0.0').should equal false
        end

        it "casts '-0.1' to true" do
          subject.to_db('-0.1').should equal true
        end
      end
    end
  end

  describe Neo4j::Shared::TypeConverters::JSONConverter do
    subject { Neo4j::Shared::TypeConverters::JSONConverter }

    let(:links) { {neo4j: 'http://www.neo4j.org', neotech: 'http://www.neotechnology.com/'} }

    it 'translates from and to database' do
      db_value = Neo4j::Shared::TypeConverters::JSONConverter.to_db(links)
      ruby_value = Neo4j::Shared::TypeConverters::JSONConverter.to_ruby(db_value)
      db_value.class.should eq String
      ruby_value.class.should eq Hash
      ruby_value['neo4j'].should eq 'http://www.neo4j.org'
    end
  end

  describe Neo4j::Shared::TypeConverters::YAMLConverter do
    subject { Neo4j::Shared::TypeConverters::YAMLConverter }

    let(:links) { {neo4j: 'http://www.neo4j.org', neotech: 'http://www.neotechnology.com/'} }

    it 'translates from and to database' do
      db_value = Neo4j::Shared::TypeConverters::YAMLConverter.to_db(links)
      ruby_value = Neo4j::Shared::TypeConverters::YAMLConverter.to_ruby(db_value)
      db_value.class.should eq String
      ruby_value.class.should eq Hash
      ruby_value[:neo4j].should eq 'http://www.neo4j.org'
    end
  end

  describe Neo4j::Shared::TypeConverters::DateConverter do
    subject { Neo4j::Shared::TypeConverters::DateConverter }

    let(:now) { Time.at(1_352_538_487).utc.to_date }

    it 'translate from and to database' do
      db_value = Neo4j::Shared::TypeConverters::DateConverter.to_db(now)
      ruby_value = Neo4j::Shared::TypeConverters::DateConverter.to_ruby(db_value)
      ruby_value.class.should eq(Date)
      ruby_value.to_s.should eq(now.to_s)
    end
  end


  describe Neo4j::Shared::TypeConverters::TimeConverter do
    subject { Neo4j::Shared::TypeConverters::TimeConverter }

    let(:now) { Time.now }

    it 'translate from and to database' do
      db_value = Neo4j::Shared::TypeConverters::TimeConverter.to_db(now)
      ruby_value = Neo4j::Shared::TypeConverters::TimeConverter.to_ruby(db_value)

      ruby_value.class.should eq(Time)
      ruby_value.to_s.should eq(now.to_s)
    end
  end

  describe Neo4j::Shared::TypeConverters::DateTimeConverter do
    subject { Neo4j::Shared::TypeConverters::DateTimeConverter }

    before(:each) do
      @dt = 1_352_538_487
      @hr = 3600
    end

    its(:to_db, DateTime.parse('2012-11-10T09:08:07-06:00')) { should eq(@dt + 6 * @hr) }
    its(:to_db, DateTime.parse('2012-11-10T09:08:07-04:00')) { should eq(@dt + 4 * @hr) }
    its(:to_db, DateTime.parse('2012-11-10T09:08:07-02:00')) { should eq(@dt + 2 * @hr) }
    its(:to_db, DateTime.parse('2012-11-10T09:08:07+00:00')) { should eq(@dt) }
    its(:to_db, DateTime.parse('2012-11-10T09:08:07+02:00')) { should eq(@dt - 2 * @hr) }
    its(:to_db, DateTime.parse('2012-11-10T09:08:07+04:00')) { should eq(@dt - 4 * @hr) }
    its(:to_db, DateTime.parse('2012-11-10T09:08:07+06:00')) { should eq(@dt - 6 * @hr) }

    describe 'to_ruby' do
      it 'translate a Integer back to DateTime' do
        subject.to_ruby(@dt + 6 * @hr).should eq(DateTime.parse('2012-11-10T09:08:07-06:00'))
      end
    end

    it 'translate from and to database' do
      value = DateTime.parse('2012-11-10T09:08:07+00:00') # only utc support
      db_value = Neo4j::Shared::TypeConverters::DateTimeConverter.to_db(value)
      ruby_value = Neo4j::Shared::TypeConverters::DateTimeConverter.to_ruby(db_value)
      ruby_value.class.should eq(DateTime)
      ruby_value.to_s.should eq(value.to_s)
    end
  end
end
