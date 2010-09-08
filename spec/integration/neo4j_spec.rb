require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j, :type => :integration do

  it "#ref_node returns the reference node" do
   Neo4j.ref_node.should be_kind_of(Java::org.neo4j.graphdb.Node)
  end

  it "#config allows to set the storage path where the database should exist on the filesystem" do
    #Neo4j.config {|c| c[:storage_path]}
  end
end
