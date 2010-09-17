require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::Node, "index", :type => :transactional do

  it "can index and search on two properties" do
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


  it "updates an index automatically when a property changes" do
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

  it "deleting an indexed property should not be found" do
    puts "add index"
#    Neo4j::Node.index :name
    puts " done"
    new_node = Neo4j::Node.new :name => 'andreas'
    #new_node.add_index 'name', 'andreas'
    new_tx

#    Neo4j::Node.find('name: andreas').first.should == new_node

    # when deleting an indexed property
    new_node = Neo4j::Node.load(new_node.neo_id)
    #puts "new_node #{new_node.neo_id}"
    #new_node[:name] = nil
    #new_node.removeProperty('name')
    new_tx
    #Neo4j::Node.find('name: andreas').first.should_not == new_node
  end

end