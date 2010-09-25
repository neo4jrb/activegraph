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
    Vehicle.find('wheels:"4" AND colour: "blue"').first.should be_kind_of(Vehicle)
    Car.find('wheels:"4" AND colour: "blue"').first.should be_kind_of(Vehicle)
    Vehicle.find('wheels:"4" AND colour: "blue"').should include(c)
  end

  it "can not found if searching on two indexes of different type" do
    c = Vehicle.new(:brand => 'Saab Automobile AB', :wheels => 4, :colour => 'blue')
    new_tx
    Vehicle.find('brand: "Saab"', :type => :fulltext).should include(c)
    Vehicle.find('brand:"Saab" AND wheels: "4"', :type => :exact).should_not include(c)
  end

  it "can use the same index for a subclass" do
    bike = Vehicle.new(:brand => 'monark', :wheels => 2)
    volvo = Car.new(:brand => 'volvo', :wheels => 4)
    new_tx
    Car.find('brand: volvo', :type => :fulltext).first.should == volvo
    Car.find('wheels: 4', :type => :exact).first.should == volvo
    Vehicle.find('brand: monark', :type => :fulltext).first.should == bike
    Car.find('wheels: 2').first.should == bike # this is strange but this is the way it works for now
  end

  it "returns an empty Enumerable if not found" do
    Car.find('wheels: 999').first.should be_nil
    Car.find('wheels: 999').should be_empty
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


  it "should work when inserting a lot of data in a single transaction" do
    # Much much fast doing inserting in one transaction
    100.times do |x|
      Neo4j::Node.new
      Car.new(:brand => 'volvo', :wheels => x)
    end
    new_tx


    100.times do |x|
      Car.find("wheels: #{x}").first.should_not be_nil
    end
  end
end

describe Neo4j::Node, "index", :type => :transactional do
  before(:each) do
    Neo4j::Node.index(:name) # default :exact
    Neo4j::Node.index(:age) # default :exact
    Neo4j::Node.index(:description, :type => :fulltext)
  end

  after(:each) do
    # make sure we clean up after each test
    Neo4j::Transaction.run do
      Neo4j::Node.clear_index_type :exact
      Neo4j::Node.clear_index_type :fulltext
    end
    Neo4j::Node.rm_index_type :exact
    Neo4j::Node.rm_index_type :fulltext
  end


  it "#asc(:field) sorts the given field as strings in ascending order " do
    Neo4j::Node.new :name => 'pelle@gmail.com'
    Neo4j::Node.new :name => 'gustav@gmail.com'
    Neo4j::Node.new :name => 'andreas@gmail.com'
    Neo4j::Node.new :name => 'örjan@gmail.com'

    new_tx
    result = Neo4j::Node.find('name: *@gmail.com').asc(:name)

    # then
    emails = result.collect { |x| x[:name] }
    emails.should == %w[andreas@gmail.com gustav@gmail.com pelle@gmail.com örjan@gmail.com]
  end

  it "#desc(:field) sorts the given field as strings in desc order " do
    Neo4j::Node.new :name => 'pelle@gmail.com'
    Neo4j::Node.new :name => 'gustav@gmail.com'
    Neo4j::Node.new :name => 'andreas@gmail.com'
    Neo4j::Node.new :name => 'örjan@gmail.com'

    new_tx
    result = Neo4j::Node.find('name: *@gmail.com').desc(:name)

    # then
    emails = result.collect { |x| x[:name] }
    emails.should == %w[örjan@gmail.com pelle@gmail.com gustav@gmail.com andreas@gmail.com ]
  end

  it "#asc(:field1,field2) sorts the given field as strings in ascending order " do
    Neo4j::Node.new :name => 'örjan@gmail.com', :age => 3
    Neo4j::Node.new :name => 'pelle@gmail.com', :age => 2
    Neo4j::Node.new :name => 'pelle@gmail.com', :age => 4
    Neo4j::Node.new :name => 'pelle@gmail.com', :age => 1
    Neo4j::Node.new :name => 'andreas@gmail.com', :age => 5

    new_tx

    result = Neo4j::Node.find('name: *@gmail.com').asc(:name, :age)

    # then
    ages = result.collect { |x| x[:age] }
    ages.should == [5, 1, 2, 4, 3]
  end

  it "#asc(:field1).desc(:field2) sort the given field both ascending and descending orders" do
    Neo4j::Node.new :name => 'örjan@gmail.com', :age => 3
    Neo4j::Node.new :name => 'pelle@gmail.com', :age => 2
    Neo4j::Node.new :name => 'pelle@gmail.com', :age => 4
    Neo4j::Node.new :name => 'pelle@gmail.com', :age => 1
    Neo4j::Node.new :name => 'andreas@gmail.com', :age => 5

    new_tx

    result = Neo4j::Node.find('name: *@gmail.com').asc(:name).desc(:age)

    # then
    ages = result.collect { |x| x[:age] }
    ages.should == [5, 4, 2, 1, 3]
  end

  it "create index on a node" do
    new_node = Neo4j::Node.new
    new_node[:name] = 'andreas'

    # when
    new_node.add_index(:name)

    # then
    Neo4j::Node.find("name: andreas", :wrapped => false).get_single.should == new_node
  end


  it "create index on a node with a given type (e.g. fulltext)" do
    new_node = Neo4j::Node.new
    new_node[:description] = 'hej'

    # when
    new_node.add_index(:description)

    # then
    Neo4j::Node.find('description: "hej"', :type => :fulltext, :wrapped => false).get_single.should == new_node
    #Neo4j::Node.find('name: "hej"').get_single.should == new_node
  end

  it "can find several nodes with the same index" do
    thing1 = Neo4j::Node.new :name => 'thing'
    thing2 = Neo4j::Node.new :name => 'thing'
    thing3 = Neo4j::Node.new :name => 'thing'

    finish_tx

    Neo4j::Node.find("name: thing", :wrapped => true).should include(thing1)
    Neo4j::Node.find("name: thing", :wrapped => true).should include(thing2)
    Neo4j::Node.find("name: thing", :wrapped => true).should include(thing3)
  end


  it "#clear_index_type clears the index" do
    new_node = Neo4j::Node.new :name => 'andreas'
    new_node.add_index(:name)

    # when
    Neo4j::Node.clear_index_type(:exact)

    # then
    Neo4j::Node.find("name: andreas").first.should_not == new_node
  end

  it "#rm_index_type will make the index not updated when transaction finishes" do
    new_node = Neo4j::Node.new :name => 'andreas'
    Neo4j::Node.find("name: andreas").first.should_not == new_node

    # when
    Neo4j::Node.rm_index_type(:exact)
    finish_tx

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
    Neo4j::Node.find('name: lala').first.should_not == new_node

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
    new_node = Neo4j::Node.new :name => 'andreas'
    new_tx
    Neo4j::Node.find('name: andreas').first.should == new_node

    # when
    new_node.del
    finish_tx

    # then
    Neo4j::Node.find('name: andreas').first.should_not == new_node
  end

  it "both deleting a property and deleting the node should work" do
    new_node = Neo4j::Node.new :name => 'andreas', :age => 21
    new_tx
    Neo4j::Node.find('name: andreas').first.should == new_node

    # when
    new_node[:name] = nil
    new_node[:age] = nil
    new_node.del
    finish_tx

    # then
    Neo4j::Node.find('name: andreas').first.should_not == new_node
  end

  it "will automatically close the connection if a block was provided with the find method" do
    indexer = Neo4j::Index::Indexer.new('mocked-indexer')
    index = double('index')
    indexer.should_receive(:index_for_type).and_return(index)
    hits = double('hits')
    index.should_receive(:query).and_return(hits)
    old_indexer = Neo4j::Node.instance_eval { @indexer }
    Neo4j::Node.instance_eval { @indexer = indexer }
    hits.should_receive(:close)
    hits.should_receive(:first).and_return("found_node")
    #puts "FIND IT first #{hits.first}"
    found_node = Neo4j::Node.find('name: andreas', :wrapped => false) { |h| h.first }
    found_node.should == 'found_node'

    # restore
    Neo4j::Node.instance_eval { @indexer = old_indexer }
  end


  it "will automatically close the connection even if the block provided raises an exception" do
    indexer = Neo4j::Index::Indexer.new('mocked-indexer')
    index = double('index')
    indexer.should_receive(:index_for_type).and_return(index)
    hits = double('hits')
    index.should_receive(:query).and_return(hits)
    old_indexer = Neo4j::Node.instance_eval { @indexer }
    Neo4j::Node.instance_eval { @indexer = indexer }
    hits.should_receive(:close)
    expect { Neo4j::Node.find('name: andreas', :wrapped => false) { |h| raise "oops" } }.to raise_error


    # restore
    Neo4j::Node.instance_eval { @indexer = old_indexer }
  end

end