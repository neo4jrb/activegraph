require 'neo4j'
require 'neo4j/spec_helper'


class Person
  include Neo4j::Node
  properties :name
  relations :friends
  
  #index :friends, :name
  # same as  index(:friends, Person, 'Friend.name') {name}
  #index :name
end

describe Person do
  before(:all) do
    start
  end

  after(:all) do
    stop
  end  
  
  it "should be possible to create a new instance" do
    person = Person.new
    person.name = 'kalle'
    
    # then
    
    result = Neo4j::Neo.instance.find_node person.neo_node_id
    #result = Person.find { name == 'kalle'}
    result.should == person
    result.name.should == 'kalle'
  end
  
  
  it "should be possible to add a friend" do
    person1 = Person.new
    person1.name = 'kalle'
    
    person2 = Person.new
    person2.name = "sune"
    
    # when
    person1.friends << person2
    
    # then
    person1.friends.to_a.should include(person2)
  end


  it "should be possible to remove a friend" do
    # given
    person1 = Person.new
    person1.name = 'kalle'
    person2 = Person.new
    person2.name = "sune"
    person1.friends << person2

    # when
    person1.relations[person2].delete
    
    # then
    person1.friends.to_a.should_not include(person2)
  end
  
end

