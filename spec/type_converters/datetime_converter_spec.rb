require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe "Date and Time converters" do

  # TODO: Add more specs, especially for time-zones!!!!

  describe "Date" do
    subject { Neo4j::TypeConverters::DateConverter }

    its(:convert?, Date)      { should be_true }
    its(:convert?, :date)     { should be_true }
    its(:convert?, DateTime)  { should be_false }
    its(:convert?, :datetime) { should be_false }
    its(:convert?, Time)      { should be_false }
    its(:convert?, :time)     { should be_false }

    its(:to_java, nil)        { should be_nil }
    its(:to_ruby, nil)        { should be_nil }
  end


  describe "Time" do
    subject { Neo4j::TypeConverters::TimeConverter }

    its(:convert?, Time)      { should be_true }
    its(:convert?, :time)     { should be_true }
    its(:convert?, DateTime)  { should be_false }
    its(:convert?, :datetime) { should be_false }

    its(:to_java, nil)        { should be_nil }
    its(:to_ruby, nil)        { should be_nil }
  end


  describe "DateTime" do
    subject { Neo4j::TypeConverters::DateTimeConverter }

    its(:convert?, DateTime)  { should be_true }
    its(:convert?, :datetime) { should be_true }
    its(:convert?, Date)      { should be_false }
    its(:convert?, :time)     { should be_false }

    its(:to_java, nil)        { should be_nil }
    its(:to_ruby, nil)        { should be_nil }
  end


end
