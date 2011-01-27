require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::Batch::Inserter do
  before(:each) do
    # It is not allowed to run the neo4j the same time as doing batch inserter
    Neo4j.shutdown
    rm_db_storage

    Neo4j::Node.index(:name) # default :exact
    Neo4j::Node.index(:age) # default :exact
    Neo4j::Node.index(:description, :type => :fulltext)
  end

  after(:each) do
    @inserter && @inserter.shutdown
    new_tx
    Neo4j::Node.rm_field_type :exact
    Neo4j::Node.rm_field_type :fulltext
    Neo4j::Node.delete_index_type  # delete all indexes
    finish_tx
  end

  context "#index Neo4j::Node" do
    before(:each) do
      @inserter = Neo4j::Batch::Inserter.new
    end

    it "#index(node, key, value)" do
      node_a = @inserter.create_node
      @inserter.index(node_a, {'name' => 'foobar42'})
      @inserter.shutdown
      Neo4j.start
      Neo4j::Node.find(:name => 'foobar42').size.should == 1
    end

    it "#create_node automatically index declared fields" do
      pending
      @inserter.create_node 'name' => 'foobar42'
      @inserter.shutdown
      Neo4j.start
      Neo4j::Node.find(:name => 'foobar42').size.should == 1
    end

  end
end