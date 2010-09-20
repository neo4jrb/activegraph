require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::Node, "index", :type => :transactional do
  class Vehicle
    include Neo4j::NodeMixin
    index :wheels
  end

  class Car < Vehicle
    indexer Vehicle # use the same indexer as Vehicle, get index on wheels
    index :brand
  end

  after(:each) do
    # make sure we clean up after each test
    Vehicle.clear_index_type
  end

  it "can index and search on two properties" do
    c = Company.new(:name => 'jayway', :revenue => 1234)
    new_tx
    Company.find('name:"jayway" AND revenue: "1234"').should include(c)
  end

  it "can use the same index for a subclass" do
    volvo = Car.new(:brand => 'volvo', :wheels => 4)
    new_tx
    Car.find('brand: volvo').first.should == volvo
  end
end

describe Neo4j::Node, "index", :type => :transactional do
  before(:each) do
    Neo4j::Node.index(:name)
  end

  after(:each) do
    # make sure we clean up after each test
    Neo4j::Node.rm_index_type(:exact)
  end

  it "create index on a node" do
    new_node = Neo4j::Node.new
    new_node[:name] = 'andreas'

    # when
    new_node.add_index(:name)

    # then
    Neo4j::Node.find("name: andreas").get_single.should == new_node
  end


  it "#rm_index_type unregisters the index from the eventhandler and clear the index" do
    new_node = Neo4j::Node.new :name => 'andreas'
    new_node.add_index(:name)

    # when
    Neo4j::Node.rm_index_type(:exact)

    # then
    Neo4j::Node.find("name: andreas").first.should_not == new_node
    Neo4j::Node.index_type?(:exact).should be_false
    Neo4j::Node.index?(:name).should be_false

    # clean up
    Neo4j::Node.index(:name)
  end


  it "does not remove old index when a property is reindexed" do
    new_node = Neo4j::Node.new
    new_node[:name] = 'Kalle Kula'
    new_node.add_index(:name)

    # when
    new_node[:name] = 'lala'
    new_node.add_index(:name)

    # then
    Neo4j::Node.find('name: lala').first.should == new_node
    Neo4j::Node.find('name: "Kalle Kula"').first.should == new_node
  end

  it "#rm_index removes an index" do
    new_node = Neo4j::Node.new
    new_node[:name] = 'Kalle Kula'
    new_node.add_index(:name)

    # when
    new_node.rm_index(:name)

    new_node[:name] = 'lala'
    new_node.add_index(:name)

    # then
    Neo4j::Node.find('name: lala').first.should == new_node
    Neo4j::Node.find('name: "Kalle Kula"').first.should_not == new_node
  end


  # FUNKAR

  it "updates an index automatically when a property changes" do
    new_node = Neo4j::Node.new
    new_node[:name] = 'Kalle Kula'

    new_tx
    Neo4j::Node.find('name: "Kalle Kula"').first.should == new_node

    new_node[:name] = 'lala'

    new_tx

    # then
    Neo4j::Node.find('name: lala').first.should == new_node
    Neo4j::Node.find('name: "Kalle Kula"').first.should_not == new_node
  end

  it "deleting an indexed property should not be found" do
    new_node = Neo4j::Node.new :name => 'andreas'
    new_tx

    Neo4j::Node.find('name: andreas').first.should == new_node

    # when deleting an indexed property
    new_node[:name] = nil
    new_tx
    Neo4j::Node.find('name: andreas').first.should_not == new_node
  end

end