require File.join(File.dirname(__FILE__), '..', 'spec_helper')


module Neo4j
  module Test
    class TestIndex
      include Neo4j::NodeMixin
      index :name
      index :desc, :type => :fulltext
      index_names[:exact] = 'new_location'
    end
  end
end


describe Neo4j::Node, "index_names", :type => :transactional do
  before(:each) do
    Neo4j.threadlocal_ref_node = nil
  end

  it "can be used to configure where the index is stored on the filesystem" do
    Neo4j::Test::TestIndex.index_names[:exact].should == "new_location"
  end

  it "has a default file location" do
    Neo4j::Test::TestIndex.index_names[:fulltext].should == "Neo4j_Test_TestIndex-fulltext"
  end

  it "creates a folder on the filesystem containing the lucene index" do
    Neo4j::Test::TestIndex.new :name => 'hoho', :desc => "hej hopp hello"
    finish_tx
    path = File.join(Neo4j.config[:storage_path], "index", "lucene", "node", Neo4j::Test::TestIndex.index_names[:exact])
    File.exist?(path).should be_true

    path = File.join(Neo4j.config[:storage_path], "index", "lucene", "node", Neo4j::Test::TestIndex.index_names[:fulltext])
    File.exist?(path).should be_true
  end

  context "when threadlocal_ref_node is set" do
    context "when reference node defines _index_prefix" do
      class IndexPrefixReferenceNode < Neo4j::Rails::Model
        def _index_prefix
          "Foo" + self.id
        end
      end

      it "should use the _index_prefix and classname to build index name" do
        ref_node = IndexPrefixReferenceNode.create!(:name => 'Ignore this for building prefix')
        Neo4j.threadlocal_ref_node = ref_node

        IceCream.index_names[:fulltext].should == "Foo#{ref_node.id}_IceCream-fulltext"
        IceCream.index_names[:exact].should == "Foo#{ref_node.id}_IceCream-exact"
      end
    end

    context "when reference node does not define _index_prefix but has name property" do
      it "should use name property and classname to build index name" do
        ref_node = Neo4j::Node.new(:name => 'Ref1')
        Neo4j.threadlocal_ref_node = ref_node

        IceCream.index_names[:fulltext].should == "Ref1_IceCream-fulltext"
        IceCream.index_names[:exact].should == "Ref1_IceCream-exact"
      end
    end

    context "when reference node does not define _index_prefix and has no name property" do
      it "should use only classname to build index name" do
        ref_node = Neo4j::Node.new
        Neo4j.threadlocal_ref_node = ref_node

        IceCream.index_names[:fulltext].should == "IceCream-fulltext"
        IceCream.index_names[:exact].should == "IceCream-exact"
      end
    end
  end
end

describe Neo4j::Relationship, "find", :type => :transactional do
  before(:each) do
    Neo4j::Relationship.index(:strength)
  end

  after(:each) do
    new_tx
    Neo4j::Relationship.rm_field_type :exact
    Neo4j::Relationship.rm_field_type :fulltext
    Neo4j::Relationship.delete_index_type  # delete all indexes
    finish_tx
  end

  it "can index when Neo4j::Relationship are created , just like nodes" do
    a            = Neo4j::Node.new
    b            = Neo4j::Node.new
    r            = Neo4j::Relationship.new(:friends, a, b)
    r[:strength] = 'strong'
    finish_tx
    Neo4j::Relationship.find('strength: strong').first.should == r
  end

  it "can remove index when Neo4j::Relationship is deleted, just like nodes" do
    a            = Neo4j::Node.new
    b            = Neo4j::Node.new
    r            = Neo4j::Relationship.new(:friends, a, b)
    r[:strength] = 'weak'
    new_tx
    r2           = Neo4j::Relationship.find('strength: weak').first
    r2.should == r

    r2.del
    finish_tx

    Neo4j::Relationship.find('strength: weak').should be_empty
  end

end

describe Neo4j::Node, "find", :type => :transactional do
  before(:each) do
    Neo4j::Node.index(:name) # default :exact
    Neo4j::Node.index(:age) # default :exact
    Neo4j::Node.index(:description, :type => :fulltext)
  end

  after(:each) do
    new_tx
    Neo4j::Node.rm_field_type :exact
    Neo4j::Node.rm_field_type :fulltext
    Neo4j::Node.delete_index_type  # delete all indexes
    finish_tx
  end


  it "#asc(:field) sorts the given field as strings in ascending order " do
    Neo4j::Node.new :name => 'pelle@gmail.com'
    Neo4j::Node.new :name => 'gustav@gmail.com'
    Neo4j::Node.new :name => 'andreas@gmail.com'
    Neo4j::Node.new :name => 'orjan@gmail.com'

    new_tx
    result = Neo4j::Node.find('name: *@gmail.com').asc(:name)

    # then
    emails = result.collect { |x| x[:name] }
    emails.should == %w[andreas@gmail.com gustav@gmail.com orjan@gmail.com pelle@gmail.com]
  end

  it "#desc(:field) sorts the given field as strings in desc order " do
    Neo4j::Node.new :name => 'pelle@gmail.com'
    Neo4j::Node.new :name => 'gustav@gmail.com'
    Neo4j::Node.new :name => 'andreas@gmail.com'
    Neo4j::Node.new :name => 'zebbe@gmail.com'

    new_tx
    result = Neo4j::Node.find('name: *@gmail.com').desc(:name)

    # then
    emails = result.collect { |x| x[:name] }
    emails.should == %w[zebbe@gmail.com pelle@gmail.com gustav@gmail.com andreas@gmail.com ]
  end

  it "#asc(:field1,field2) sorts the given field as strings in ascending order " do
    Neo4j::Node.new :name => 'zebbe@gmail.com', :age => 3
    Neo4j::Node.new :name => 'pelle@gmail.com', :age => 2
    Neo4j::Node.new :name => 'pelle@gmail.com', :age => 4
    Neo4j::Node.new :name => 'pelle@gmail.com', :age => 1
    Neo4j::Node.new :name => 'andreas@gmail.com', :age => 5

    new_tx

    result = Neo4j::Node.find('name: *@gmail.com').asc(:name, :age)

    # then
    ages   = result.collect { |x| x[:age] }
    ages.should == [5, 1, 2, 4, 3]
  end

  it "#asc(:field1).desc(:field2) sort the given field both ascending and descending orders" do
    Neo4j::Node.new :name => 'zebbe@gmail.com', :age => 3
    Neo4j::Node.new :name => 'pelle@gmail.com', :age => 2
    Neo4j::Node.new :name => 'pelle@gmail.com', :age => 4
    Neo4j::Node.new :name => 'pelle@gmail.com', :age => 1
    Neo4j::Node.new :name => 'andreas@gmail.com', :age => 5

    new_tx

    result = Neo4j::Node.find('name: *@gmail.com').asc(:name).desc(:age)

    # then
    ages   = result.collect { |x| x[:age] }
    ages.should == [5, 4, 2, 1, 3]
  end

  it "create index on a node" do
    new_node        = Neo4j::Node.new
    new_node[:name] = 'andreas'

    # when
    new_node.add_index(:name)

    # then
    Neo4j::Node.find("name: andreas", :wrapped => false).get_single.should == new_node
  end


  it "create index on a node with a given type (e.g. fulltext)" do
    new_node               = Neo4j::Node.new
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


  it "#delete_index_type clears the index" do
    pending "Looks like I can't delete a whole lucene index and recreated it again"
    new_node = Neo4j::Node.new :name => 'andreas'
    new_node.add_index(:name)

    # when
    Neo4j::Node.delete_index_type(:exact)

    new_tx
    # then
    Neo4j::Node.find("name: andreas").first.should_not == new_node
  end

  it "#rm_field_type will make the index not updated when transaction finishes" do
    new_node = Neo4j::Node.new :name => 'andreas'
    Neo4j::Node.find("name: andreas").first.should_not == new_node

    # when
    Neo4j::Node.rm_field_type(:exact)
    finish_tx

    # then
    Neo4j::Node.find("name: andreas").first.should_not == new_node
    Neo4j::Node.index_type?(:exact).should be_false
    Neo4j::Node.index?(:name).should be_false

    # clean up
    Neo4j::Node.index(:name)
  end


  it "does not remove old index when a property is reindexed" do
    new_node        = Neo4j::Node.new
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
    new_node        = Neo4j::Node.new
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
    new_node        = Neo4j::Node.new
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
    new_node        = Neo4j::Node.new :name => 'andreas'
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
    new_node        = Neo4j::Node.new :name => 'andreas', :age => 21
    new_tx
    Neo4j::Node.find('name: andreas').first.should == new_node

    # when
    new_node[:name] = nil
    new_node[:age]  = nil
    new_node.del
    finish_tx

    # then
    Neo4j::Node.find('name: andreas').first.should_not == new_node
  end

  it "will automatically close the connection if a block was provided with the find method" do
    indexer     = Neo4j::Index::Indexer.new('mocked-indexer', :node)
    index       = double('index')
    indexer.should_receive(:index_for_type).and_return(index)
    hits        = double('hits')
    index.should_receive(:query).and_return(hits)
    old_indexer = Neo4j::Node._indexer
    Neo4j::Node.instance_eval { @_indexer = indexer }
    hits.should_receive(:close)
    hits.should_receive(:first).and_return("found_node")
    found_node  = Neo4j::Node.find('name: andreas', :wrapped => false) { |h| h.first }
    found_node.should == 'found_node'

    # restore
    Neo4j::Node.instance_eval { @_indexer = old_indexer }
  end


  it "will automatically close the connection even if the block provided raises an exception" do
    indexer     = Neo4j::Index::Indexer.new('mocked-indexer', :node)
    index       = double('index')
    indexer.should_receive(:index_for_type).and_return(index)
    hits        = double('hits')
    index.should_receive(:query).and_return(hits)
    old_indexer = Neo4j::Node.instance_eval { @_indexer }
    Neo4j::Node.instance_eval { @_indexer = indexer }
    hits.should_receive(:close)
    expect { Neo4j::Node.find('name: andreas', :wrapped => false) { |h| raise "oops" } }.to raise_error


    # restore
    Neo4j::Node.instance_eval { @_indexer = old_indexer }
  end

end

