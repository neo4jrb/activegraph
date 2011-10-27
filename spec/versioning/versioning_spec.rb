require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe "Versioning" do
  class VersionableModel < Neo4j::Rails::Model
    include Neo4j::Versioning
  end

  class SportsCar < Neo4j::Rails::Model
    include Neo4j::Versioning
    property :brand
  end

  class Driver < Neo4j::Rails::Model
    include Neo4j::Versioning
    property :name
    has_n(:sports_cars)
  end

  it "should return version number" do
    versionable_model = VersionableModel.create!(:property => 'property1')
    versionable_model.current_version.should == 1
  end

  it "should increment version when a model is revised" do
    versionable_model = VersionableModel.create!(:property => 'property1')
    versionable_model.current_version.should == 1
    versionable_model.revise
    versionable_model.current_version.should == 2
  end

  it "should return a previous version" do
    versionable_model = VersionableModel.create!(:property => 'property1')
    versionable_model[:second_property] = 'property 2'
    versionable_model.save!
    versionable_model.current_version.should == 2
    versionable_model.version(1)[:second_property].should be_nil
    versionable_model.version(1)[:property].should == 'property1'
  end

  it "should create correctly named relationships to and from snapshots" do
    ferarri = SportsCar.create!(:name => 'Ferarri')
    porsche = SportsCar.create!(:name => 'Porsche')
    driver = Driver.create!(:name => 'Driver')
    driver.sports_cars << ferarri
    driver.save!
    driver.sports_cars << porsche
    driver.save!
    driver.current_version.should == 3
    driver.version(1).outgoing(:sports_cars).should be_empty
    driver.version(2).outgoing(:sports_cars).should include(ferarri)
    driver.version(3).outgoing(:sports_cars).should include(ferarri,porsche)
  end
end