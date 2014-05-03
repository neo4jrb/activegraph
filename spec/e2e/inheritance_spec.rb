require 'spec_helper'


describe 'Inheritance', type: :e2e do
  class Node 
    include Neo4j::ActiveNode
    property :created_at, type: DateTime
    property :updated_at, type: DateTime
  end
  
  class Vehicle < Node
    include Neo4j::ActiveNode
    property :name, type: String
    index :name
  end

  class Car < Vehicle
    property :model
    index :model
  end

  before(:each) do
    Car.destroy_all
    Vehicle.destroy_all
    @bike = Vehicle.create(name: 'bike')
    @volvo = Car.create(name: 'volvo', model: 'v60')
    @saab = Car.create(name: 'saab', model: '900')
  end

  describe 'find' do
    it 'can find using subclass index' do
      @volvo.labels.should =~ [:Car, :Vehicle]
      Car.find(name: 'volvo').should eq(@volvo)
      Vehicle.find(name: 'volvo').should eq(@volvo)
    end

    it 'can find using baseclass index' do
      @saab.labels.should =~ [:Car, :Vehicle]
      Car.find(model: '900').should eq(@saab)
      Vehicle.find(model: '900').should eq(@saab)
    end

  end

  describe 'all' do
    it 'can find all sub and base classes' do
      Vehicle.all.to_a.should =~ [@saab, @bike, @volvo]
      Car.all.to_a.should =~ [@saab, @volvo]
    end
  end
end