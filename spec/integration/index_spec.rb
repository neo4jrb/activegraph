require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::Node, "index", :type => :transactional do
  class Vehicle
    include Neo4j::NodeMixin
    index :wheels
  end

  class Car < Vehicle
    indexer Vehicle # use the same indexer as Vehicle, get index on wheels
    index :brand, :type => :fulltext
    index :colour
  end

  after(:each) do
    # make sure we clean up after each test (enough to clean Vehicle since they share index)
    Vehicle.clear_index_type
  end

  it "can index and search on two properties if index has the same type" do
    c = Vehicle.new(:wheels => 4, :colour => 'blue')
    new_tx
    Vehicle.find('wheels:"4" AND colour: "blue"').should include(c)
  end

  it "can not found if searching on two indexes of different type" do
    c = Vehicle.new(:brand => 'Saab Automobile AB', :wheels => 4, :colour => 'blue')
    new_tx
    Vehicle.find('brand: "Saab"', :fulltext).should include(c)
    Vehicle.find('brand:"Saab" AND wheels: "4"', :exact).should_not include(c)
  end

  it "can use the same index for a subclass" do
    bike = Vehicle.new(:brand => 'monark', :wheels => 2)
    volvo = Car.new(:brand => 'volvo', :wheels => 4)
    new_tx
    Car.find('brand: volvo', :fulltext).first.should == volvo
    Car.find('wheels: 4', :exact).first.should == volvo
    Vehicle.find('brand: monark', :fulltext).first.should == bike
    Car.find('wheels: 2').first.should == bike  # this is strange but this is the way it works for now
  end

  it "returns an empty Enumerable if not found" do
    Car.find('wheels: 999').first.should be_nil
    [*Car.find('wheels: 999')].should be_empty
  end

  it "will remove the index when the node is deleted" do
    c = Car.new(:brand => 'Saab Automobile AB', :wheels => 4, :colour => 'blue')
    new_tx
    Vehicle.find('wheels:"4" AND colour: "blue"').should include(c)

    # when
    c.del
    new_tx

    # then
    Car.find('wheels:"4"').should_not include(c)
    Vehicle.find('colour:"blue"').should_not include(c)
    Vehicle.find('wheels:"4" AND colour: "blue"').should_not include(c)
  end


  it "should work when inserting a lot of data" do
    # Much much fast doing like this
   100.times do |x|
      Neo4j::Node.new
      Car.new(:brand => 'volvo', :wheels => x)
    end
    new_tx

    # than creating a TX for every insert
    10.times do |x|
      Neo4j::Node.new
      Car.new(:brand => 'volvo', :wheels => (x + 100))
      new_tx
    end

    110.times do |x|
      Car.find("wheels: #{x}").first.should_not be_nil
    end
  end
end

describe Neo4j::Node, "index", :type => :transactional do
  before(:each) do
    Neo4j::Node.index(:name)  # default :exact
    Neo4j::Node.index(:description, :type => :fulltext)
  end

  after(:each) do
    # make sure we clean up after each test
    Neo4j::Node.rm_index_type(:exact)
    Neo4j::Node.rm_index_type(:fulltext)
  end

  it "create index on a node" do
    new_node = Neo4j::Node.new
    new_node[:name] = 'andreas'

    # when
    new_node.add_index(:name)

    # then
    Neo4j::Node.find("name: andreas").get_single.should == new_node
  end


  it "create index on a node with a given type (e.g. fulltext)" do
    new_node = Neo4j::Node.new
    new_node[:description] = 'hej'
#    new_node[:name] = 'hej'

    puts "new_node #{new_node.neo_id}"
    # when
    #new_tx
    new_node.add_index(:description)

    # then
    Neo4j::Node.find('description: "hej"', :fulltext).get_single.should == new_node
    #Neo4j::Node.find('name: "hej"').get_single.should == new_node
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

  it "deleting the node deletes its index" do
    pending
    new_node = Neo4j::Node.new :name => 'andreas'
    new_tx
    Neo4j::Node.find('name: andreas').first.should == new_node

    # when
    new_node.del
    new_tx

    # then
    Neo4j::Node.find('name: andreas').first.should_not == new_node
  end
end