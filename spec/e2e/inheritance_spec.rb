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
      property :specs # Hash
      index :name
      serialize :specs
    end

    class Car < Vehicle
      property :model
      index :model
    end
  end

  before(:each) do
    [InheritanceTest::Car, InheritanceTest::Vehicle].each {|c| c.delete_all }
    @bike = InheritanceTest::Vehicle.create(name: 'bike')
    @volvo = InheritanceTest::Car.create(name: 'volvo', model: 'v60')
    @saab = InheritanceTest::Car.create(name: 'saab', model: '900')
  end

  describe 'find' do
    it 'can find using subclass index' do
      @volvo.labels.should =~ [:'InheritanceTest::Car', :'InheritanceTest::Node', :'InheritanceTest::Vehicle']
      InheritanceTest::Car.where(name: 'volvo').first.should eq(@volvo)
      InheritanceTest::Vehicle.where(name: 'volvo').first.should eq(@volvo)
    end

    it 'can find using baseclass index' do
      @saab.labels.should =~ [:'InheritanceTest::Car', :'InheritanceTest::Node', :'InheritanceTest::Vehicle']
      InheritanceTest::Car.where(model: '900').first.should eq(@saab)
      InheritanceTest::Vehicle.where(model: '900').first.should eq(@saab)
    end

  end

  describe 'all' do
    it 'can find all sub and base classes' do
      InheritanceTest::Vehicle.all.to_a.should =~ [@saab, @bike, @volvo]
      InheritanceTest::Car.all.to_a.should =~ [@saab, @volvo]
    end
  end

  describe 'indexes' do
    it 'inherits the indexes of the base class' do
      expect(InheritanceTest::Car.indexed_properties).to include :name
    end
  end

  describe 'serialization' do
    let!(:toyota) do
      InheritanceTest::Car.create(name: 'toyota', model: 'camry')
    end

    it 'successfully saves and returns hashes from the base class' do
      specs = {weight: 3000, doors: 4}
      toyota.specs = specs
      toyota.save
      expect(toyota.specs).to eq specs
      expect(toyota.specs.class).to eq Hash
    end
  end
end
