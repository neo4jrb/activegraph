$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'spec_helper'



describe "Person" do
  before(:all) do
    start
    undefine_class :Person

    class Person
      include Neo4j::NodeMixin
      property :name, :age
      has_n :friends
      index :name
      index :'friends.age'
    end
  end

  after(:all) do
    stop
  end

  it "should be possible to create a new instance" do
    person = Neo4j::Transaction.run do
      Person.new
    end

    Neo4j::Transaction.run do
      result = Neo4j.load_node person.neo_id
      result.should == person
    end

  end

  it "should find persons who has friends with a specific age" do
    me = nil
    Neo4j::Transaction.run do

      me = Person.new
      me.age = 10
      you = Person.new
      you.age = 20

      me.friends << you
    end

    # when
    Neo4j::Transaction.run do
      res = Person.find('friends.age' => '20')

      # then
      res.size.should == 1
      res[0].should == me
    end
  end

  it "should be possible to find it given its name" do
    person1 = person2 = nil
    Neo4j::Transaction.run do

      person1 = Person.new
      person1.name = 'kalle'
      person2 = Person.new
      person2.name = "sune"
    end

    # when
    Neo4j::Transaction.run do

      result = Person.find(:name => 'kalle')

      # then
      result.should include(person1)
      result.should_not include(person2)
      result.size.should == 1
    end
  end


  it "should be possible to add a friend" do
    person1 = person2 = nil
    Neo4j::Transaction.run do
      person1 = Person.new
      person1.name = 'kalle'

      person2 = Person.new
      person2.name = "sune"

      # when
      person1.friends << person2
    end


    Neo4j::Transaction.run do
      # then
      [*person1.friends].should include(person2)
    end
  end


  it "should be possible to remove a friend" do
    person1 = person2 = nil
    Neo4j::Transaction.run do
      # given
      person1 = Person.new
      person1.name = 'kalle'
      person2 = Person.new
      person2.name = "sune"
      person1.friends << person2

      # when
      person1.rels[person2].delete

      # then
      [*person1.friends].should_not include(person2)
    end
  end

end

