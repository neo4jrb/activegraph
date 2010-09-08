require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::Transaction, :type => :integration do

  it "#run runs the provided block in an transaction" do
    Neo4j::Transaction.finish
    node =  Neo4j::Transaction.run {Neo4j::Node.new}
    Neo4j::Node.should exist(node.id)
  end

end