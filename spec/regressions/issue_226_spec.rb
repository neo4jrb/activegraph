module Regressions
  require 'spec_helper'

  class Issue226 < Neo4j::Rails::Model
    has_one :thing
  end

  describe "Issue 226, make sure other_node returns a wrapped node" do
    it "has a correct count" do
      a = Issue226.create
      b = Issue226.create
      a.thing = b
      a.save!

      rel = a.thing_rel
      rel.start_node.should == a
      rel.end_node.should == b
      rel.other_node(a).neo_id.should == b.neo_id
      rel.other_node(a).class.should == Issue226
      rel.other_node(a).should == b
    end
  end
end