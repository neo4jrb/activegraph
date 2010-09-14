require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::AggregateMixin, :type => :transactional do


  class User
    include Neo4j::NodeMixin
    extend Neo4j::AggregateMixin  # TODO this should be automaticlly included in NodeMixin

#    aggregate(:rich) { |props| props[:salary] > 20 }
    aggregate(:all) {}

  end

  it "ascsa" do
    pending
    eh = Neo4j.started_db.event_handler
    User.should respond_to(:all)
    a = User.new
    b = User.new
    puts "FINISH TX"
    Neo4j::Transaction.finish
    puts "NEW TX"
    Neo4j::Transaction.new
    User.all.should include(a,b)
    #User.all.should include(a,b)
  end
end
