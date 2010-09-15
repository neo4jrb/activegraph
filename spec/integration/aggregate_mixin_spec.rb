require File.join(File.dirname(__FILE__), '..', 'spec_helper')


class User
  include Neo4j::NodeMixin
end


describe "Neo4j::Node#aggregate" do


  before(:all) do
    rm_db_storage
    User.aggregate :all
  end

  after(:all) do
    Neo4j::Transaction.run {User.delete_aggregate :all }
    Neo4j.shutdown
    rm_db_storage
  end


  it "aggregate(:all) will generate an all method returning all instance of the class" do

    a,b = nil
    Neo4j::Transaction.run do
      User.should respond_to(:all)
      a = User.new
      b = User.new
    end

    Neo4j::Transaction.run do
      User.all.should include(a,b)
    end
  end

end
