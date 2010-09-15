require File.join(File.dirname(__FILE__), '..', 'spec_helper')


class User
  include Neo4j::NodeMixin
  extend Neo4j::AggregateMixin  # TODO this should be automaticlly included in NodeMixin

#    aggregate(:rich) { |props| props[:salary] > 20 }
  aggregate(:all) {}

end

describe Neo4j::AggregateMixin, :type => :transactional do



  it "aggregate(:all) will generate an all method returning all instance of the class" do
    puts "HOHO -------------------------------------------"
#    eh = Neo4j.started_db.event_handler
    User.should respond_to(:all)
    puts "CREATE USER OBJECTS"
    a = User.new
    b = User.new
    puts "FINISH TX #{a.neo_id} #{b.neo_id}"
    Neo4j::Transaction.finish
    puts "NEW TX"
    Neo4j::Transaction.new
    User.all.should include(a,b)
    #User.all.should include(a,b)
  end
end
