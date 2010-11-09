require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class RequiredProperty < Neo4j::Rails::Model
	property :required, :null => false
end

class LengthProperty < Neo4j::Rails::Model
	property :length, :limit => 128
end

class DefaultProperty < Neo4j::Rails::Model
	property :default, :default => "Test"
end

class LotsaProperties < Neo4j::Rails::Model
	property :required, :null => false
	property :length, :limit => 128
	property :nothing
end

class DateProperties < Neo4j::Rails::Model
	property :date_time, 	:type => DateTime
	property :created_on, :type => Date
	property :time, 			:type => Time
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
		it "should have the default" do
			subject.default.should == "Test"
		end
	end
	
	context "when the property is set" do
		it "shouldn't have the default" do
			subject.class.new(:default => "Changed").default.should == "Changed"
		end
	end
end

describe LotsaProperties do
	it "should have 2 callbacks" do
		subject.class._validate_callbacks.size.should == 2
	end
end

describe DateProperties do
	before(:each) do
		#subject.time = @time = Time.now
		subject.date_time = @date_time = Time.now
		subject.created_on = @date = Date.today
	end
	
	it_should_behave_like "a new model"
	it_should_behave_like "a loadable model"
	it_should_behave_like "a saveable model"
	it_should_behave_like "a creatable model"
	it_should_behave_like "a destroyable model"
	it_should_behave_like "an updatable model"
	
	it "should have the correct date" do
		subject.created_on.should == @date
		subject.created_on.should be_a(Time)
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
	
	pending "should have the correct time" do
		subject.time.to_s.should == @time.to_s
		subject.time.should be_a(Time)
	end
end
