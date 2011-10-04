require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::Batch::Inserter do
  before(:each) do
    # It is not allowed to run the neo4j the same time as doing batch inserter
    Neo4j.shutdown
    rm_db_storage

    Neo4j::Node.index(:name) # default :exact
    Neo4j::Node.index(:age) # default :exact
    Neo4j::Node.index(:description, :type => :fulltext)

    @inserter = Neo4j::Batch::Inserter.new
    Neo4j.threadlocal_ref_node = nil    
  end

  after(:each) do
    @inserter && @inserter.shutdown
    new_tx
    Neo4j::Node.rm_field_type :exact
    Neo4j::Node.rm_field_type :fulltext
    Neo4j::Node.delete_index_type  # delete all indexes
    finish_tx
  end

  context "#index :name and :age on Neo4j::Node" do
    it "create_node creates an index" do
      @inserter.create_node 'name' => 'foobar42'
      @inserter.shutdown
      Neo4j.start
      Neo4j::Node.find(:name => 'foobar42').size.should == 1
    end

    it "does not create an index if index was not declared" do
      @inserter.create_node 'city' => '123'
      @inserter.shutdown
      Neo4j.start
      Neo4j::Node.find(:city => '123').size.should == 0
    end

    it "lucene index can be used before inserter shutdown" do
      node = @inserter.create_node 'name' => 'foo'
      @inserter.index_flush
      @inserter.index_get('name', 'foo').first.should == node
      @inserter.index_query('name: foo').first.should == node
    end
  end

  context "#index via" do
    before(:all) do
      @movie_class = create_node_mixin
      @actor_class = create_node_mixin
      @actor_class.has_n(:acted_in).to(@movie_class)
      @actor_class.index :name
      @movie_class.has_n(:actors).from(@actor_class, :acted_in)
      @movie_class.index :title, :via => :actors
    end

    it "when a related node is created it should update the other nodes index" do
      keanu  = @inserter.create_node({'name' => 'keanu'}, @actor_class)
      matrix = @inserter.create_node({'title' => 'matrix'}, @movie_class)
      speed  = @inserter.create_node({'title' => 'speed'}, @movie_class)
      @inserter.create_rel(@actor_class.acted_in, keanu, matrix)
      @inserter.create_rel(@actor_class.acted_in, keanu, speed)
      @inserter.shutdown
      Neo4j.start

      @actor_class.find('name: keanu').should_not be_empty
      @actor_class.find('title: matrix').should_not be_empty
      @actor_class.find('title: speed').should_not be_empty
    end

  end
end