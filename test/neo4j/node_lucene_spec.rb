$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'


describe "Neo4j.start" do
  before(:all) do
    undefine_class :TestNode
    class TestNode
      include Neo4j::NodeMixin
      property :name, :age
      index :name
    end
  end

  before(:each) { start }
  after(:each) { stop }

  it "should keep index on filesystem if specifed" do
    Lucene::Config[:store_on_file] = true

    t = TestNode.new
    t.name = 'hello'
    File.exist?(Lucene::Config[:storage_path]).should be_true
  end

  it "should keep index in RAM if filesystem path for lucene index is not specified" do
    # given
    # make index does not exist on file
    FileUtils.rm_rf Lucene::Config[:storage_path]
    File.exist?(Lucene::Config[:storage_path]).should be_false

    # when
    Lucene::Config[:store_on_file] = false
    t = TestNode.new
    t.name = 'hello'

    # then
    File.exist?(LUCENE_INDEX_LOCATION).should be_false
  end

end
  
describe "Neo4j & Lucene Transaction Synchronization:" do
  before(:all) do
    start
    undefine_class :TestNode
    class TestNode 
      include Neo4j::NodeMixin
      property :name, :age
      index :name, :age
    end
  end
  after(:all) do
    stop
  end  

  it "should specify which properties to index using NodeMixin#index method" do
    TestNode.indexer.property_indexer.properties.should include(:name, :age)
    TestNode.indexer.property_indexer.properties.size.should == 2
  end

  it "should not update the index if the transaction rollsback" do
    # given
    TestNode.find(:name => 'hello').size.should == 0
    n1 = nil
    Neo4j::Transaction.run do |t|
      n1 = TestNode.new
      n1.name = 'hello'
  
      # when
      t.failure
    end
  
    # then
    n1.should_not be_nil
    TestNode.find(:name => 'hello').should_not include(n1)
  end
  
  it "should reindex when a property has been changed" do
    # given
    n1 = TestNode.new
    n1.name = 'hi'
    TestNode.find(:name => 'hi').should include(n1)
  
  
    # when
    n1.name = "oj"
  
    # then
    TestNode.find(:name => 'hi').should_not include(n1)
    TestNode.find(:name => 'oj').should include(n1)
  end
  
  it "should remove the index when a node has been deleted" do
    # given
    n1 = TestNode.new
    n1.name = 'remove'
  
    # make sure we can find it
    TestNode.find(:name => 'remove').should include(n1)
  
    # when
    n1.delete
  
    # then
    TestNode.find(:name => 'remove').should_not include(n1)
  end
end

describe "A node with no lucene index" do
  before(:all) do
    start
    class TestNodeWithNoIndex
      include Neo4j::NodeMixin
    end

  end

  after(:all) do
    stop
  end

  it "should return no nodes in a query" do
    found = TestNodeWithNoIndex.find(:age => 0)

    found.size.should == 0
  end
end

describe "Find with sorting" do
  before(:all) do
    start
    undefine_class :Person7
    class Person7
      include Neo4j::NodeMixin
      property :name, :city
      index :name
      index :city
    end
    @kalle = Person7.new {|p| p.name = 'kalle'; p.city = 'malmoe'}
    @andreas = Person7.new {|p| p.name = 'andreas'; p.city = 'malmoe'}
    @sune = Person7.new {|p| p.name = 'sune'; p.city = 'malmoe'}
    @anders = Person7.new {|p| p.name = 'anders'; p.city = 'malmoe'}
  end

  after(:all) do
    stop
  end

  it "should find and sort using a hash query" do
    persons = Person7.find(:city => 'malmoe').sort_by(:name)
    persons.size.should == 4
    persons[0].should == @anders
    persons[1].should == @andreas
    persons[2].should == @kalle
    persons[3].should == @sune
  end

  it "should not sort when not specified to do so" do
    persons = Person7.find(:city => 'malmoe')
    persons.size.should == 4
    sorted =  persons[0] == @anders &&
      persons[1] == @andreas &&
      persons[2] == @kalle &&
      persons[3] == @sune
    sorted.should == false
  end

end


describe "Find Nodes using Lucene and tokenized index" do
  before(:all) do
    start
    undefine_class :Person
    class Person
      include Neo4j::NodeMixin
      property :name, :name2
      index :name,   :tokenized => true
      index :name2, :tokenized => false # default
      def to_s
        "Person '#{self.name}'"
      end
    end
    names = ['Andreas Ronge', 'Kalle Kula', 'Laban Surename', 'Sune Larsson', 'hej hopp']
    @foos = []
    names.each {|n|
      node = Person.new
      node.name = n
      node.name2 = n
      @foos << node
    }
  end

  after(:all) do
    stop
  end

  it "should find one node using one token" do
    found = Person.find(:name => 'hej')
    found.size.should == 1
    found.should include(@foos[4])
  end

  it "should find one node using a string query" do
    found = Person.find("name:'hej'")
    found.size.should == 1
    found.should include(@foos[4])

    found = Person.find("name:hopp")
    found.size.should == 1
    found.should include(@foos[4])

  end

  it "should find one node using a wildcard string query" do
    found = Person.find("name:Andreas*")
    found.size.should == 1
    found.should include(@foos[0])
  end

  it "should find using lowercase one token search" do
    found = Person.find(:name => 'kula')
    found.size.should == 1
    found.should include(@foos[1])
  end

  it "should find using part of a word" do
    #    pending "Tokenized search fields not working yet"
    found = Person.find(:name => 'ronge')
    found.size.should == 1
    found.should include(@foos[0])
  end

  it "should not found a node using a none tokenized field when quering using one token" do
    found = Person.find(:name2 => 'ronge')
    found.size.should == 0
  end

end

describe "Find nodes using Lucene" do
  before(:all) do
    start
    class TestNode
      include Neo4j::NodeMixin
      property :name, :age, :male, :height
      index :name
      index :age, :type => Fixnum
      index :male
      index :height, :type => Float
    end
    @foos = []
    5.times {|n|
      node = TestNode.new
      node.name = "foo#{n}"
      node.age = n # "#{n}"
      node.male = (n == 0)
      node.height = n * 0.1
      @foos << node
    }
    @bars = []
    5.times {|n|
      node = TestNode.new
      node.name = "bar#{n}"
      node.age = n # "#{n}"
      node.male = (n == 0)
      node.height = n * 0.1
      @bars << node
    }

    @node100 = TestNode.new  {|n| n.name = "node"; n.age = 100}

  end

  after(:all) do
    stop
  end

  it "should find one node" do
    found = TestNode.find(:name => 'foo2')
    found[0].name.should == 'foo2'
    found.should include(@foos[2])
    found.size.should == 1
  end

  it "should find one node using a range" do
    found = TestNode.find(:age => 0..2)
    found.size.should == 6
    found.should include(@foos[1])

    found = TestNode.find(:age => 100)
    found.size.should == 1
    found.should include(@node100)
  end

  it "should find two nodes" do
    found = TestNode.find(:age => 0)
    found.should include(@foos[0])
    found.should include(@bars[0])
    found.size.should == 2
  end

  it "should find using two fields" do
    found = TestNode.find(:age => 0, :name => 'foo0')
    found.should include(@foos[0])
    found.size.should == 1
  end

  it "should find using a boolean property query" do
    found = TestNode.find(:male => true)
    found.should include(@foos[0], @bars[0])
    found.size.should == 2
  end

  it "should find using a float property query" do
    found = TestNode.find(:height => 0.2)
    found.should include(@foos[2], @bars[2])
    found.size.should == 2
  end


  it "should find using a DSL query" do
    found = TestNode.find{(age == 0) && (name == 'foo0')}
    found.should include(@foos[0])
    found.size.should == 1
  end

  it "should be possible to remove an index" do
    # given
    found = TestNode.find(:name => 'foo2')
    found.size.should == 1

    # when
    TestNode.remove_index(:name)
    TestNode.update_index

    # then
    found = TestNode.find(:name => 'foo2')
    found.size.should == 0
  end

  describe "Find Nodes using Lucene Date index" do
    before(:each) do
      undefine_class :PersonNode
      start
      class PersonNode
        include Neo4j::NodeMixin
        property :name
        property :born, :type => Date
        index :name
        index :born, :type => Date
      end
    end
    
    after(:each) do
      stop
    end

    it "should find using a date query" do
      result = PersonNode.find("born:[20080427 TO 20100203]")
      result.size.should == 0
      node = PersonNode.new
      node.born.should be_nil
      node.name = 'kalle'
      node.born = Date.new 2008,05,06

      # when
      result = PersonNode.find("born:[20080427 TO 20100203]")
      result.size.should == 1
    end
  end

  describe "Find Nodes using Lucene DateTime index" do
    before(:each) do
      undefine_class :PersonNode
      start
      class PersonNode
        include Neo4j::NodeMixin
        property :name
        property :since, :type => DateTime
        index :name
        index :since, :type => DateTime
      end
    end

    after(:each) do
      stop
    end

    it "should find using a date query" do
      result = PersonNode.find("since:[200804271504 TO 201002031534]")
      result.size.should == 0
      node = PersonNode.new
      node.since.should be_nil
      node.name = 'kalle'
      # only UTC Times are supported
      node.since = DateTime.civil 2008,04,27,15,25,59

      # when
      result = PersonNode.find("since:[200804271504 TO 201002031534]")
      result.size.should == 1
      result[0].since.class.should == DateTime
      result[0].since.year.should == 2008
      result[0].since.min.should == 25
    end
  end

end

