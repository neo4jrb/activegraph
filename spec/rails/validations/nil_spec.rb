require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

class NilTest < Neo4j::Rails::Model
	property :the_property
	
	validates :the_property, :non_nil => true
end

describe NilTest do
	context "when invalid" do
		it_should_behave_like "a new model"
		it_should_behave_like "an unsaveable model"
		it_should_behave_like "an uncreatable model"
		it_should_behave_like "a non-updatable model"
		it "should have errors on the property after save" do
			subject.save
			subject.errors[:the_property].should_not be_empty
		end
	end
	
	context "when valid" do
		before(:each) { subject.the_property = "" }
		
		it_should_behave_like "a new model"
    it_should_behave_like "a loadable model"
    it_should_behave_like "a saveable model"
    it_should_behave_like "a creatable model"
    it_should_behave_like "a destroyable model"
    it_should_behave_like "an updatable model"
  end
end
