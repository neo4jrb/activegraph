require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::ActiveModel, "value" do

  it "validation works on the created value object" do
    v = ActivePerson.value
    v.should_not be_valid
    v.name = 'andreas'
    v.should be_valid
  end

  it "can be initialize just like the #new" do
    v = ActivePerson.value(:name => 'andreas')
    v.should be_valid
  end

  it "save should raise an exception if not run in an transaction" do
    v = ActivePerson.value(:name => 'andreas')
    expect { v.save }.to raise_error
  end


  it "save should create a new node when run in a transaction" do
    v = ActivePerson.value(:name => 'andreas')
    Neo4j::Transaction.new
    v.save
    Neo4j::Node.should exist(v)
    Neo4j::Transaction.finish
  end

  it "has nil as id befored saved" do
    v = ActivePerson.value(:name => 'andreas')
    v.neo_id.should == nil
  end

end

describe Neo4j::ActiveModel, :type => :integration do

  it "#save should validate the model and return true if it was valid" do

    # option 1 - save calls valid? and finish the transaction if valid
    p = ActivePerson.new
    p.save.should be_false
  end


  it "Active Model validation should work" do
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
    p.attribute_changed?('name').should == true
    pending "ActiveModel::Dirty does almost work - name_change does work"
    p.name_change.should == 'kalle'
    p.name_was.should == nil
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

