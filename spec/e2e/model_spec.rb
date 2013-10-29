require 'spec_helper'

describe 'Neo4j::Rails::Model', api: :server do

  class Person
    include Neo4j::ActiveModel
  end

  it 'can persist a new object' do
    person = Person.new
    person.neo_id.should be_nil
    person.save
    person.neo_id.should be_a(Fixnum)
  end

  it 'can set properties' do
    person = Person.new(name: 'andreas', age: 21)
    person[:name].should == 'andreas'
    person[:age].should == 21
    person.save
    person[:name].should == 'andreas'
    person[:age].should == 21
  end

  it 'can create the node' do
    person = Person.create(name: 'andreas', age: 21)
    person.neo_id.should be_a(Fixnum)
    person[:name].should == 'andreas'
    person[:age].should == 21
    person.exist?.should be_true
  end

  it 'can be deleted' do
    person = Person.create(name: 'andreas', age: 21)
    person.del
    person.exist?.should be_false
  end

  it "they can be all found" do
    person1 = Person.create(name: 'person1', age: 21)
    person2 = Person.create(name: 'person2', age: 21)
    Person.find_all.should include(person1, person2)
  end
end