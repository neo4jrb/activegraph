require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class RequiredProperty < Neo4j::Rails::Model
	property :required,       :null => false
end

class LengthProperty < Neo4j::Rails::Model
	property :length,         :limit => 128
end

class DefaultProperty < Neo4j::Rails::Model
	property :default,        :default => "Test"
	property :false_property, :default => false
	property :date_property,  :default => Time.now, :type => Time
end

class LotsaProperties < Neo4j::Rails::Model
	property :required,       :null => false
	property :length,         :limit => 128
	property :nothing
end

class DateProperties < Neo4j::Rails::Model
	property :date_time, 	    :type => DateTime
	property :date_property,  :type => Date
	property :time,           :type => Time
end

class ProtectedProperties < Neo4j::Rails::Model
	property :name
	property :admin, :default => false

	attr_accessible :name
end

class FixnumProperties < Neo4j::Rails::Model
  property :age, :type => Fixnum
end

class FloatProperties < Neo4j::Rails::Model
  property :val, :type => Float
end

describe FixnumProperties do
  context "before save" do
    before(:each) do
      subject.age = "123"
    end

    it "should convert the property to a fixnum" do
      subject.age.class.should == Fixnum
    end
  end

  context "after save" do
    before(:each) do
      subject.age = "123"
      subject.save
    end

    it "should convert the property to a fixnum" do
      subject.age.class.should == Fixnum
      subject.age.should == 123
    end
  end

end

describe FloatProperties do
  context "before save" do
    before(:each) do
      subject.val = "3.14"
    end

    it "should convert the property to a float" do
      subject.val.class.should == Float
    end
  end

  context "after save" do
    before(:each) do
      subject.val = 3.14
      subject.save
    end

    it "should convert the property to a float" do
      subject.val.class.should == Float
      subject.val.should == 3.14
    end
  end
end

describe RequiredProperty do
	it_should_behave_like "a new model"
	it_should_behave_like "an unsaveable model"
	it_should_behave_like "an uncreatable model"
	it_should_behave_like "a non-updatable model"

	context "when valid" do
		before(:each) do
			subject.required = "true"
		end

		it_should_behave_like "a new model"
		it_should_behave_like "a loadable model"
		it_should_behave_like "a saveable model"
		it_should_behave_like "a creatable model"
		it_should_behave_like "a destroyable model"
		it_should_behave_like "an updatable model"
	end
end

describe LengthProperty do
	context "when too big" do
		before(:each) do
			subject.length = "a" * 256
		end

		it_should_behave_like "a new model"
		it_should_behave_like "an unsaveable model"
		it_should_behave_like "an uncreatable model"
		it_should_behave_like "a non-updatable model"
	end

	context "when small enough" do
		before(:each) do
			subject.length = "aaa"
		end

		it_should_behave_like "a new model"
		it_should_behave_like "a loadable model"
		it_should_behave_like "a saveable model"
		it_should_behave_like "a creatable model"
		it_should_behave_like "a destroyable model"
		it_should_behave_like "an updatable model"
	end

	context "with no length at all" do
		it_should_behave_like "a new model"
		it_should_behave_like "a loadable model"
		it_should_behave_like "a saveable model"
		it_should_behave_like "a creatable model"
		it_should_behave_like "a destroyable model"
		it_should_behave_like "an updatable model"
	end
end

describe DefaultProperty do
	context "when the property isn't set" do
		it "should have the default in #attributes" do
			subject.attributes.should include("default")
			subject.attributes["default"].should == "Test"
			subject.attributes["false_property"].should === false
			subject.attributes["date_property"].should be_a(Time)
		end

		it "should have the default" do
			subject.default.should == "Test"
			subject.false_property.should === false
			subject.date_property.should be_a(Time)
		end

		it_should_behave_like "a saveable model"
	end

	context "when the property is set" do
		it "shouldn't have the default" do
			subject.class.new(:default => "Changed").default.should == "Changed"
		end

		it "shouldn't have the default on reload" do
			c = subject.class.create!(:default => "Changed")
			c.default.should == "Changed"
			c.class.find(c.id).default.should == "Changed"
		end
	end
end

describe LotsaProperties do
	it "should have 3 callbacks" do
		subject.class._validate_callbacks.size.should == 3
	end
end

describe DateProperties do
  before(:each) do
    subject.time          = @time = Time.now
    subject.date_time     = @date_time = DateTime.now
    subject.date_property = @date = Date.today
  end

  it_should_behave_like "a new model"
  it_should_behave_like "a loadable model"
  it_should_behave_like "a saveable model"
  it_should_behave_like "a creatable model"
  it_should_behave_like "a destroyable model"
  it_should_behave_like "an updatable model"

  it "should give back the correct type even before it is saved" do
    subject.time = Time.now
    subject.time.is_a?(Time)
  end

  context "update_attributes" do
    it "with Time" do
      params = {"time(1i)"=>"2006", "time(2i)"=>"1", "time(3i)"=>"5", "time(4i)"=>"02", "time(5i)"=>"03"}
      subject.update_attributes(params)
      subject.time.class.should == Time
      subject.time.year.should == 2006
      subject.time.month.should == 1
      subject.time.day.should == 5
      #subject.time.hour.should == 2 # TODO it is stored as UTC time !!!
      #subject.time.min.should == 3
    end

    it "with Date" do
      params = {"date_property(1i)"=>"2031", "date_property(2i)"=>"2", "date_property(3i)"=>"10"}
      subject.update_attributes(params)
      subject.date_property.year.should == 2031
      subject.date_property.month.should == 2
      subject.date_property.day.should == 10
      subject.date_property.class.should == Date
    end

    it "with DateTime" do
      params = {"date_time(1i)"=>"2006", "date_time(2i)"=>"1", "date_time(3i)"=>"5", "date_time(4i)"=>"02", "date_time(5i)"=>"03"}
      subject.update_attributes(params)
      subject.date_time.year.should == 2006
      subject.date_time.month.should == 1
      subject.date_time.day.should == 5
      subject.date_time.hour.should == 2
      subject.date_time.min.should == 3
      subject.date_time.class.should == DateTime
    end
  end


  context "After save and reload" do
    subject do
      @time      ||= Time.now
      @date_time ||= DateTime.now
      @date      ||= Date.today
      dp         = DateProperties.create!(:time => @time, :date_time => @date_time, :date_property => @date)
      DateProperties.find(dp.id)
    end

    it "should have the correct date" do
      subject.date_property.should == @date
      subject.date_property.should be_a(Date)
    end

    it "should have the correct date_time" do
      subject.date_time.year.should == @date_time.year
      subject.date_time.month.should == @date_time.month
      subject.date_time.day.should == @date_time.day
      subject.date_time.hour.should == @date_time.hour
      subject.date_time.min.should == @date_time.min
      subject.date_time.sec.should == @date_time.sec
      subject.date_time.should be_a(DateTime)
    end

    it "should have the correct time" do
      subject.time.to_s.should == @time.to_s
      subject.time.should be_a(Time)
    end
  end
end

describe ProtectedProperties do
	context "with mass-assignment of protected properties" do
		subject do
			@p ||= ProtectedProperties.create!(:name => "Ben", :admin => true)
			@p.admin
		end

		it { should === false }
	end

	context "with mass-assignment of select properties" do
		subject do
			@p ||= ProtectedProperties.create!(:name => "Ben")
			@p.admin
		end

		it { should === false }
	end

	context "when set without the safeguard" do
		subject do
			@p ||= ProtectedProperties.create!(:name => "Ben")
			@p.send(:attributes=, { :admin => true }, false)
			@p.admin
		end

		it { should == true }
	end

	context "when setting using attributes=" do
		subject do
			@p ||= ProtectedProperties.create!
			@p.attributes = { :name => "Ben", :admin => true }
			@p.admin
		end

		it { should === false }
	end

	context "when set using the single assignment" do
		subject do
			@p ||= ProtectedProperties.create!
			@p.admin = true
			@p.admin
		end

		it { should == true }
	end
end
