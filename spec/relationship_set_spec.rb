require File.join(File.dirname(__FILE__), 'spec_helper')

describe "RelationshipSet" do
  before(:each) do
    @set = RelationshipSet.new
  end

  it "should return false contains for nonexistent entries" do
    @set.contains?(4,:foo).should be_false
  end

  it "should return true for registered entries" do
    @set.add(4,:foo)
    @set.contains?(4,:foo).should be_true
  end
end