require File.join(File.dirname(__FILE__), '..', 'spec_helper')


class User
  include Neo4j::NodeMixin
end



describe "Neo4j::Node#aggregate" do


  before(:all) do
    rm_db_storage
    User.aggregate :all
    User.aggregate(:old) { |node| node[:age] > 10 }
  end
#
  after(:all) do
    Neo4j::Transaction.run { User.delete_aggregates }
    finish_tx
    Neo4j.shutdown
    rm_db_storage
  end


  it "aggregate properties" do
    new_tx
    a = User.new :age => 25
    b = User.new :age => 5
    finish_tx
    User.all.should include(a)
    User.all.should include(b)
    User.old.should include(a)
    User.old.should_not include(b)
  end

end

