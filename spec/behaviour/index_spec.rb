$LOAD_PATH.unshift File.join(File.dirname(__FILE__))
require 'spec_helper'


describe Neo4j::Node, "Index", :type => :integration do
  after(:each) do
    # make sure we clean up after each test
    Neo4j::Node.rm_index(:name)
  end

  it "create index on a node" do
    new_node = Neo4j::Node.new
    new_node[:name] = 'Andreas Ronge'

    # when
    new_node.index(:name)

    # then
    Neo4j::Node.find(:name, 'Andreas Ronge').first.should == new_node
  end

  it "does not remove old index when a property is reindexed" do
    new_node = Neo4j::Node.new
    new_node[:name] = 'Kalle Kula'
    new_node.index(:name)

    # when
    new_node[:name] = 'lala'
    new_node.index(:name)

    # then
    Neo4j::Node.find(:name, 'lala').first.should == new_node
    Neo4j::Node.find(:name, 'Kalle Kula').first.should == new_node
  end

  it "#rm_index removes an index" do
    new_node = Neo4j::Node.new
    new_node[:name] = 'Kalle Kula'
    new_node.index(:name)

    # when
    new_node.rm_index(:name)

    new_node[:name] = 'lala'
    new_node.index(:name)
#    Neo4j::Transaction.finish

    # then
    Neo4j::Node.find(:name, 'lala').first.should == new_node
    Neo4j::Node.find(:name, 'Kalle Kula').first.should_not == new_node
  end


  it "updates an index automatically when it's registered" do
    Neo4j::Node.index :name

    new_node = Neo4j::Node.new
    new_node[:name] = 'Kalle Kula'
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    new_node[:name] = 'lala'

    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    # then
    Neo4j::Node.find(:name, 'lala').first.should == new_node
    Neo4j::Node.find(:name, 'Kalle Kula').first.should_not == new_node
  end
end