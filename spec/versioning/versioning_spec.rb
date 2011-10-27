require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe "Versioning" do
  class VersionableModel < Neo4j::Rails::Model
    include Neo4j::Versioning
  end

  it "should return version" do
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
    versionable_model.version(1).property.should == 'property1'
  end
end