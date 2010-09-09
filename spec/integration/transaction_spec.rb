require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::Transaction, :type => :integration do

  it "#run runs the provided block in an transaction" do
    # make sure we don't already have one running transaction'
    Neo4j::Transaction.finish
    node =  Neo4j::Transaction.run { Neo4j::Node.new }
    Neo4j::Node.should exist(node)
  end


  it "#run should rollback the transaction if an exception is raised" do
    # make sure we don't already have one running transaction'
    Neo4j::Transaction.finish
    node = nil

    expect do
      Neo4j::Transaction.run do
        node = Neo4j::Node.new
        Neo4j::Node.should exist(node)
        raise "oops"
      end
    end.to raise_error

    Neo4j::Node.should_not exist(node)
  end

end