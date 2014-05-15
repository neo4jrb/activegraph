require 'spec_helper'


describe 'Inheritance', type: :e2e do
  module InheritanceTest
    class Node
      include Neo4j::ActiveNode
      property :created_at, type: DateTime
      property :updated_at, type: DateTime
    end

    class Vehicle < Node
      property :name, type: String
      index :name
    end

    class Car < Vehicle
      property :model
      index :model
    end
  end

  before(:each) do
    InheritanceTest::Car.destroy_all
    InheritanceTest::Vehicle.destroy_all
    @bike = InheritanceTest::Vehicle.create(name: 'bike')
    @volvo = InheritanceTest::Car.create(name: 'volvo', model: 'v60')
    @saab = InheritanceTest::Car.create(name: 'saab', model: '900')
  end

  describe 'find' do
    it 'can find using subclass index' do
      @volvo.labels.should =~ [:'InheritanceTest::Car', :'InheritanceTest::Node', :'InheritanceTest::Vehicle']
      InheritanceTest::Car.find(name: 'volvo').should eq(@volvo)
      InheritanceTest::Vehicle.find(name: 'volvo').should eq(@volvo)
    end

    it 'can find using baseclass index' do
      @saab.labels.should =~ [:'InheritanceTest::Car', :'InheritanceTest::Node', :'InheritanceTest::Vehicle']
      InheritanceTest::Car.find(model: '900').should eq(@saab)
      InheritanceTest::Vehicle.find(model: '900').should eq(@saab)
    end

  end

  describe 'all' do
    it 'can find all sub and base classes' do
      InheritanceTest::Vehicle.all.to_a.should =~ [@saab, @bike, @volvo]
      InheritanceTest::Car.all.to_a.should =~ [@saab, @volvo]
    end
  end
end