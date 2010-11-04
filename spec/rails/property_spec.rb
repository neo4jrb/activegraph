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
		pending "should have the default" do
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
