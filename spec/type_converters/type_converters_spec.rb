require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::TypeConverters, :type => :transactional do
  context "my own converter that respond to #to_java and #to_ruby in the Neo4j::TypeConverters module" do
    before(:all) do
      Neo4j::TypeConverters.converters = nil  # reset the list of converters since we have already started neo4j 

      module Neo4j::TypeConverters
        class MyConverter
          class << self

            def convert?(type)
              type == Object
            end

            def to_java(val)
              "silly:#{val}"
            end

            def to_ruby(val)
              val.sub(/silly:/, '')
            end
          end
        end
      end

      @clazz = create_node_mixin do
        property :thing, :type => Object

        def to_s
          "Thing #{thing}"
        end
      end
    end

    it "should convert when node initialized with a hash of properties" do
      a = @clazz.new :thing => 'hi'
      a.get_property('thing').should == 'silly:hi'
    end

    it "should convert back to ruby" do
      a = @clazz.new :thing => 'hi'
      a.thing.should == 'hi'
    end

    it "should convert when accessor method is called" do
      a       = @clazz.new
      a.thing = 'hi'
      a.get_property('thing').should == 'silly:hi'
    end

    it "should NOT convert when 'raw' set_property(key,value) method is called" do
      a = @clazz.new
      a.set_property('thing', 'hi')
      a.get_property('thing').should == 'hi'
    end

  end

  describe Neo4j::TypeConverters, "finding a converter" do
    subject { Neo4j::TypeConverters.converter(type) }

    context "when no type given" do
      let(:type) { nil }
      it { should == Neo4j::TypeConverters::DefaultConverter }
    end

    context "when known type is given" do
      let(:type) { :date }
      it { should == Neo4j::TypeConverters::DateConverter }
    end

    context "when unknown type is given" do
      let(:type) { :nobody_know_this_kind_of_type_that_i_propbably_missssspelled }
      it "should raise error" do
        expect { subject }.to raise_error
      end
    end
  end

  context Neo4j::TypeConverters::SymbolConverter, "property :status => Symbol" do
    before(:all) do
      @clazz = create_node_mixin do
        property :status, :type => Symbol
      end
    end

    it "should save Symbol as String" do
      v = @clazz.new :status => :active
      val = v._java_node.get_property('status')
      val.class.should == String
    end

    it "should load as Symbol" do
      v = @clazz.new :status => :active
      v.status.should == :active
    end

    it "should treat String as Symbol" do
      v = @clazz.new :status => 'active'
      v.status.should == :active
    end
  end


  context Neo4j::TypeConverters::StringConverter, "property :name => String" do
    before(:all) do
      @clazz = create_node_mixin do
        property :name, :type => String
      end
    end

    it "should save String as String" do
      v = @clazz.new :name => 'me'
      val = v._java_node.get_property('name')
      val.class.should == String
    end

    it "should load as String" do
      v = @clazz.new :name => 'me'
      v.name.should == 'me'
    end

    it "should treat anything as String" do
      @clazz.new(:name=>123).name.should == '123'
      @clazz.new(:name=>1.23).name.should == '1.23'
      @clazz.new(:name=>:sym).name.should == 'sym'
      @clazz.new(:name=> Object.new).name.class.should == String
    end
  end



  context Neo4j::TypeConverters::DateConverter, "property :born => Date" do
    before(:all) do
      @clazz = create_node_mixin do
        property :born, :type => Date
        index :born
      end
    end

    it "should save the date as an Fixnum" do
      v = @clazz.new :born => Date.today
      val = v._java_node.get_property('born')
      val.class.should == Fixnum
    end

    it "should load the date as an Date" do
      now = Date.today
      v = @clazz.new :born => now
      v.born.should == now
    end

    it "can be ranged searched: find(:born).between(date_a, Date.today)" do
      yesterday = Date.today - 1
      v = @clazz.new :born => yesterday
      new_tx
      found = [*@clazz.find(:born).between(Date.today-2, Date.today)]
      found.size.should == 1
      found.should include(v)
    end
  end


  context Neo4j::TypeConverters::DateTimeConverter, "property :since => DateTime" do
    before(:all) do
      @clazz = create_node_mixin do
        property :since, :type => DateTime
        index :since
      end
    end

    it "should save the date as an Fixnum" do
      v = @clazz.new :since => DateTime.new(1842, 4, 2, 15, 34, 0)
      val = v._java_node.get_property('since')
      val.class.should == Fixnum
    end

    it "should load the date as an Date" do
      since = DateTime.new(1842, 4, 2, 15, 34, 0)
      v = @clazz.new :since => since
      v.since.should == since
    end
    
    # Just to be compatible with the devise tests
    it "should be able to load Dates too" do
      since = Date.civil(1977)
      v = @clazz.new :since => since
      v.since.should be_a(DateTime)
      v.since.year.should == since.year
      v.since.month.should == since.month
      v.since.day.should == since.day
      v.since.hour.should == 0
      v.since.min.should == 0
      v.since.sec.should == 0
    end

    it "can be ranged searched: find(:born).between(date_a, Date.today)" do
      a = DateTime.new(1992, 1, 2, 15, 20, 0)
      since = DateTime.new(1992, 4, 2, 15, 34, 0)
      b = DateTime.new(1992, 10, 2, 15, 55, 0)
      v = @clazz.new :since => since
      new_tx
      found = [*@clazz.find(:since).between(a, b)]
      found.size.should == 1
      found.should include(v)
    end
  end
  
  context Neo4j::TypeConverters::TimeConverter, "property :since => Time" do
    before(:all) do
      @clazz = create_node_mixin do
        property :since, :type => Time
      end
    end
    
    # Just to be compatible with the devise tests
    it "should be able to load Dates too" do
      since = Date.civil(1977)
      v = @clazz.new :since => since
      v.since.should be_a(Time)
      v.since.year.should == since.year
      v.since.month.should == since.month
      v.since.day.should == since.day
      v.since.hour.should == 0
      v.since.min.should == 0
      v.since.sec.should == 0
    end

    it "should not double-change time zone" do
      t = Time.utc(2011, 12, 14, 21, 56)
      v = @clazz.new :since => t
      v.since = v.since
      v.since = v.since.getutc
      v.since = v.since
      v.since.should == t
      v.since = v.since.localtime
      v.since = v.since
      v.since.should === t
    end
  end


end
