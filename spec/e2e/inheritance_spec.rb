require 'spec_helper'


describe 'Inheritance', type: :e2e do
  class Vehicle
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
      Vehicle.all.should include(@saab, @bike, @volvo)
      Car.all.should include(@saab, @volvo)
      Car.all.should_not include(@bike)
    end
  end
end