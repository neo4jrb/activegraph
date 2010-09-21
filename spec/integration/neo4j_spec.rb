require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j do

  # restore the configuration
  after(:all) { Neo4j::Config.setup }


  after(:each) do
    finish_tx
    Neo4j.shutdown
    FileUtils.rm_rf Neo4j::Config[:storage_path]
  end

  def create_new_storage(path)
    Neo4j::Config.use { |c| c[:storage_path] = path }
    FileUtils.rm_rf Neo4j::Config[:storage_path]
    File.should_not exist(path)
  end

  it "#ref_node returns the reference node" do
    Neo4j.ref_node.should be_kind_of(Java::org.neo4j.graphdb.Node)
  end

  it "#ref_node, can have relationship to this node" do
    new_tx
    a = Neo4j::Node.new
    b = Neo4j::Node.new
    a.outgoing(:jo) << b
    lambda {Neo4j.ref_node.outgoing(:skoj) << a << b}.should change(Neo4j.ref_node.rels, :size).by(2)

    lambda {a.del; b.del}.should change(Neo4j.ref_node.rels, :size).by(-2)
  end


  it "#all_nodes returns a Enumerable of all nodes in the graph database " do
    # given created three nodes in a clean database
    new_location =   File.join(Dir.tmpdir, 'neo4j-rspec-tests2')
    create_new_storage(new_location)
    new_tx
    created_nodes = 3.times.map{ Neo4j::Node.new.id }

    # when
    found_nodes = Neo4j.all_nodes.map {|node| node.id}

    # then
    found_nodes.should include(*created_nodes)
    found_nodes.should include(Neo4j.ref_node.id)
  end

  it "is possible to configure a new location of the database on the filesystem" do
    new_location =   File.join(Dir.tmpdir, 'neo4j-rspec-tests3')
    create_new_storage(new_location)

    tx = Neo4j::Transaction.new
    Neo4j::Node.new
    File.should exist(new_location)
    tx.success
    tx.finish
  end
end
