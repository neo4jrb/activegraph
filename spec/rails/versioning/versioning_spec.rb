require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe "Versioning" do
  class VersionableModel < Neo4j::Rails::Model
    include Neo4j::Rails::Versioning
  end

  class SportsCar < Neo4j::Rails::Model
    include Neo4j::Rails::Versioning
    property :brand
  end

  class Driver < Neo4j::Rails::Model
    include Neo4j::Rails::Versioning
    property :name
    has_n(:sports_cars)
  end

  class ModelWithDateProperty < Neo4j::Rails::Model
    include Neo4j::Rails::Versioning
    property :date, :type => :date
  end

  it "should start version numbers at 1" do
    versionable_model = VersionableModel.create!(:property => 'property1')
    versionable_model.current_version.should == 1
  end

  it "should increment version when a model is saved" do
    versionable_model = VersionableModel.create!(:property => 'property1')
    versionable_model.current_version.should == 1
    versionable_model[:other_property] = 'other'
    versionable_model.save!
    versionable_model.current_version.should == 2
  end

  it "should return a previous version" do
    versionable_model = VersionableModel.create!(:property => 'property1')
    versionable_model[:second_property] = 'property 2'
    versionable_model.save!
    versionable_model.current_version.should == 2
    versionable_model.version(1).should be_a(Neo4j::Rails::Versioning::Snapshot)
    versionable_model.version(1)[:second_property].should be_nil
    versionable_model.version(1)[:property].should == 'property1'
  end

  it "should not save a version if there are no changes" do
    versionable_model = VersionableModel.create!(:property => 'property1')
    versionable_model[:property] = 'property 2'
    versionable_model.save
    versionable_model.save
    versionable_model.current_version.should == 2
  end

  it "should create correctly named incoming and outgoing relationships to and from snapshots" do
    ferarri = SportsCar.create!(:name => 'Ferarri')
    ferarri.version(1).incoming(:sports_cars).should be_empty
    porsche = SportsCar.create!(:name => 'Porsche')
    driver = Driver.create!(:name => 'Driver')
    driver.sports_cars << ferarri
    driver.save!
    driver.sports_cars << porsche
    driver.save!
    driver.current_version.should == 3
    ferarri[:max_speed] = 300
    ferarri.save!
    driver.version(1).outgoing(:sports_cars).should be_empty
    driver.version(2).outgoing(:sports_cars).should include(ferarri)
    driver.version(3).outgoing(:sports_cars).should include(ferarri,porsche)
    ferarri.incoming(:sports_cars).size.should == 1 #Versioning uses a relationship name with a prefix
    ferarri.version(2).incoming(:sports_cars).should include(driver)
  end

  it "should delete older versions when max_versions is exceeded" do
    class MaxVersion < Neo4j::Rails::Model
      include Neo4j::Rails::Versioning
      max_versions 2
    end
    max_version = MaxVersion.create!(:name => "Foo")
    max_version.update_attributes!(:name => "Bar")
    max_version.update_attributes!(:name => "Baz")
    max_version.update_attributes!(:name => "FooBar")
    max_version.current_version.should == 4
    max_version.version(1).should be_nil
    max_version.version(2).should be_nil
  end

  it "versions multiple instances" do
    model1 = VersionableModel.create!(:property => 'model1property')
    model2 = VersionableModel.create!(:property => 'model2property')
    model1.version(1)[:property].should == 'model1property'
    model2.version(1)[:property].should == 'model2property'
  end

  it "should not version rule and version to snapshot relationships" do
    model1 = VersionableModel.create!(:property => 'model1property')
    model1[:other] = 'other_property'
    model1.save!
    model1.version(1).rels.size().should == 1
    model1.version(1).rels.first.relationship_type.should == :version
    model1.version(2).rels.size().should == 1
    model1.version(2).rels.first.relationship_type.should == :version
  end

  it "should version models with date properties" do
    model = ModelWithDateProperty.create!(:date => Date.today)
    model.version(1)[:date].should == model.date
  end

  it "deleting an entity deletes all its versions" do
    model1 = VersionableModel.create!(:property => 'model1property')
    model1.version(1).should_not be_nil
    neo_id = model1.neo_id #Saving the ID because destroy deletes it
    classname = model1._classname
    version(classname, neo_id, 1).should_not be_nil
    model1.destroy
    version(classname, neo_id, 1).should be_nil
  end

  it "restores an older version with properties" do
    model = ModelWithDateProperty.create!(:date => Date.today)
    model[:other_property] = 'Other'
    model.save!
    model.revert_to(1)
    model[:other_property].should be_nil
    model.date.should == Date.today
    model.current_version.should == 3
  end

  it "restores an older version with relationships" do
    pending "Does not work with new active model 3.2"
    ferarri = SportsCar.create!(:name => 'Ferarri')
    ferarri.version(1).incoming(:sports_cars).should be_empty
    porsche = SportsCar.create!(:name => 'Porsche')
    driver = Driver.create!(:name => 'Driver')
    driver.sports_cars << ferarri
    driver.save!
    driver.sports_cars << porsche
    driver.save!
    driver.current_version.should == 3
    driver._java_node.rels.size.should == 6 #1 to the Driver _all node, 3 snapshots, 2 sports cars
    driver.revert_to(1)
    driver.sports_cars.should be_empty
    pending "Does not work for some reason"
    driver.current_version.should == 4
    driver._java_node.rels.size.should == 5 #4 relationships to snapshots + 1 to the Driver _all node
    driver.revert_to(2)
    driver.sports_cars.should include(ferarri)
  end

  def version(classname, neo_id, number)
    Neo4j::Rails::Versioning::Version.find(:model_classname => classname, :instance_id => neo_id, :number => number) {|query| query.first.nil? ? nil : query.first.end_node}
  end
end