require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::Node, "index", :type => :transactional do

  it "can index and search on two properties" do
    pending "should work now"
    c = Company.new(:name => 'jayway', :revenue => 1234)
    new_tx
    Company.find('name:"jayway" AND revenue: "1234"').should include(c)
  end
end

describe Neo4j::Node, "index", :type => :transactional do
  before(:each) do
    Neo4j::Node.index(:name)
  end

  after(:each) do
    # make sure we clean up after each test
    Neo4j::Node.clear_index
    Neo4j::Node.unregister_index
  end

  it "create index on a node" do
    new_node = Neo4j::Node.new
    new_node[:name] = 'andreas'

    # when
    new_node.add_index(:name)

    # then
    Neo4j::Node.find("name: andreas").get_single.should == new_node
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


  it "updates an index automatically when it's registered" do
    Neo4j::Node.index :name

    new_node = Neo4j::Node.new
    new_node[:name] = 'Kalle Kula'

    new_tx

    new_node[:name] = 'lala'

    new_tx

    # then
    Neo4j::Node.find('name: lala').first.should == new_node
    Neo4j::Node.find('name: "Kalle Kula"').first.should_not == new_node
  end

  it "when a property is deleted the node should not be found"
end