require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::ActiveModel, :type => :integration do

  it "validation should work" do
    p = ActivePerson.new
    p.should_not be_valid
    p.errors.keys[0].should == :name
    p.name = 'andreas'
    p.should be_valid
    p.errors.size.should == 0
  end

  it "find('42') should return node with id 42" do
    p = ActivePerson.new
    ActivePerson.find(p.neo_id.to_s).should == p
  end

  it "implements the ActiveModel::Dirty interface" do
    p = ActivePerson.new
    p.should_not be_changed
    p.name = 'kalle'
    p.should be_changed
    p.name_changed?.should be_true
    p.name_was.should == nil

    p.save
    p.should_not be_changed

  #   person.name = 'Bob'
  #   person.changed?       # => true
  #   person.name_changed?  # => true
  #   person.name_was       # => 'Uncle Bob'
  #   person.name_change    # => ['Uncle Bob', 'Bob']
  #   person.name = 'Bill'
  #   person.name_change    # => ['Uncle Bob', 'Bill']

  end
end

