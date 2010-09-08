require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j, :type => :integration do

  it "#ref_node returns the reference node" do
   Neo4j.ref_node.should be_kind_of(Java::org.neo4j.graphdb.Node)
  end

  it "should be possible to configure a new location of the database on the filesystem" do
    old_storage_path =Neo4j::Config[:storage_path]

    Neo4j::Config.use {|c| c[:storage_path] = 'tmp/foo'}
    FileUtils.rm_rf Neo4j::Config[:storage_path]
    File.should_not exist('tmp/foo')

    Neo4j.shutdown
    Neo4j.start
    Neo4j::Transaction.new
    Neo4j::Node.new
    File.should exist('tmp/foo')
    Neo4j::Transaction.finish

    # clean up
    Neo4j.shutdown
    FileUtils.rm_rf Neo4j::Config[:storage_path]
    Neo4j::Config[:storage_path] = old_storage_path
    Neo4j.start
    Neo4j::Transaction.new
  end
end
