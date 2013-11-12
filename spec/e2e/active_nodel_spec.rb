require 'spec_helper'

describe Neo4j::ActiveNode, api: :server do

  class Person
    include Neo4j::ActiveNode
  end

  it 'can persist a new object' do
    person = Person.new
    person.neo_id.should be_nil
    person.save
    person.neo_id.should be_a(Fixnum)
    person.exist?.should be_true
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

  it 'can be loaded by id' do
    person1 = Person.create(name: 'andreas', age: 21)
    person2 = Neo4j::Node.load(person1.neo_id)
    person2.neo_id.should == person1.neo_id
    person2.should == person1
  end

  it 'does not persist updated properties until they are saved' do
    person = Person.create(name: 'andreas', age: 21)
    person[:age] = 22

    person2 = Neo4j::Node.load(person.neo_id)
    person2[:age].should == 21
  end


  it "they can be all found" do
    person1 = Person.create(name: 'person1', age: 21)
    person2 = Person.create(name: 'person2', age: 21)
    Person.find_all.should include(person1, person2)
  end
end