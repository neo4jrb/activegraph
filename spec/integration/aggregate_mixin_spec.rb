require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::AggregateMixin, :type => :transactional do


  class User
    include Neo4j::NodeMixin
    extend Neo4j::AggregateMixin  # TODO this should be automaticlly included in NodeMixin

#    aggregate(:rich) { |props| props[:salary] > 20 }
    aggregate(:all) {}

  end

  it "ascsa" do
    eh = Neo4j.db.event_handler
    puts "EH = #{eh}"
    a = User.new
    b = User.new
    Neo4j::Transaction.finish
    Neo4j::Transaction.new
    #User.all.should include(a,b)
  end
end
