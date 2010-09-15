require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::Transaction do

  before(:all) { rm_db_storage }
  after(:all) { Neo4j.shutdown }

  it "#run runs the provided block in an transaction" do
    node =  Neo4j::Transaction.run { Neo4j::Node.new }
    node.should exist
  end


  it "#run should rollback the transaction if an exception is raised" do
    node = nil

    expect do
      Neo4j::Transaction.run do
        node = Neo4j::Node.new
        Neo4j::Node.should exist(node)
        raise "oops"
      end
    end.to raise_error

    node.should_not exist
  end


  it "ha" do
    a = Neo4j::Transaction.run do
      Neo4j::Node.new
    end
    id = a.neo_id
    puts "delete id #{id}"
    Neo4j::Transaction.run do
      x = Neo4j::Node.load(id)
      puts "got #{x} id:#{x.neo_id}"
      x.del
    end
  end


  it "#new returns a Java Transaction" do
    tx = Neo4j::Transaction.new
    tx.should be_kind_of(org.neo4j.graphdb.Transaction)
    tx.finish
  end

  it "a nested transaction that fails will fail the top transaction" do
    tx1 = Neo4j::Transaction.new
    tx2 = Neo4j::Transaction.new
    node = Neo4j::Node.new

    # when
    tx2.failure
    tx2.finish
    tx1.success

    # then
    expect { tx1.finish }.to raise_error
    node.should_not exist
  end


  it "#finish without a call to #success will not commit the transaction" do
    tx = Neo4j::Transaction.new
    node = Neo4j::Node.new
    tx.finish

    node.should_not exist
  end

  it "#success will commit the transaction" do
    tx = Neo4j::Transaction.new
    node = Neo4j::Node.new
    tx.success
    tx.finish

    node.should exist
  end

end