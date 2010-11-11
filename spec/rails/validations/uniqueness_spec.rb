require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

class UniquenessTest < Neo4j::Rails::Model
	property :name
  index    :name
	
	validates :name, :presence => true, :uniqueness => true
end

describe UniquenessTest do
  before(:each) do
    subject.class.create(:name => "test 1")
    subject.class.create(:name => "test 2")
  end

	context "when invalid" do
    before(:each) do
      subject.name = "test 1"
    end

		it_should_behave_like "a new model"
		it_should_behave_like "an unsaveable model"
		it_should_behave_like "an uncreatable model"
		it_should_behave_like "a non-updatable model"
		it "should have errors on the property after save" do
			subject.save
			subject.errors[:name].should_not be_empty
		end
	end
	
	context "when valid" do
		before(:each) { subject.name = "test" }
		
		it_should_behave_like "a new model"
    it_should_behave_like "a loadable model"
    it_should_behave_like "a saveable model"
    it_should_behave_like "a creatable model"
    it_should_behave_like "a destroyable model"
    it_should_behave_like "an updatable model"

    context "after save" do
      before(:each) do
        subject.save
        subject.reload
      end

      it { should be_valid }
    end
  end
end

describe "An unindexed unique field" do
  it "should cause an exception" do
    lambda do
      class UnindexedTest < Neo4j::Rails::Model
        property :name

        validates :name, :uniqueness => true
      end
    end.should raise_exception
  end
end
