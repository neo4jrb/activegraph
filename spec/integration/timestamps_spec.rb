require 'spec_helper'

class TimestampTest < Neo4j::Rails::Model
  property :created_at
  property :updated_at
end

class InheritedTimestampTest < TimestampTest
end

class DateTimestampTest < Neo4j::Rails::Model
  property :created_at, :type => Date, :index => :exact
end

class SubDateTimestampTest < DateTimestampTest
end


describe "Timestamp", :type => :integration do
  describe TimestampTest do
    it_should_behave_like "a timestamped model"
  end

  describe InheritedTimestampTest do
    it_should_behave_like "a timestamped model"

    it "should be correct type" do
      subject.save
      subject.created_at.class.should == Time
    end
  end

  describe DateTimestampTest do
    it "should be correct type" do
      subject.save
      subject.created_at.class.should == Date
    end
  end

  describe SubDateTimestampTest do
    it "should be correct type" do
      subject.save
      subject.created_at.class.should == Date
    end
  end
end