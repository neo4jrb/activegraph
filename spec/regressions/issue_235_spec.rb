module Regressions
  require 'spec_helper'

  class Issue235 < Neo4j::Rails::Model
    property :thing
  end

  class IssueRel235 < Neo4j::Rails::Relationship
    property :thing
  end

  describe "Issue 235, make sure frozen? does not have side effects" do
    it "works for Neo4j::Rails::Model" do
      a = Issue235.create(:thing => 2)
      a.reload
      a.thing = 42
      a.frozen?
      a.thing.should == 42
    end

    it "works for Neo4j::Rails::Relationship" do
      a = Issue235.create!
      b = Issue235.create!
      r = IssueRel235.create(:friends, a, b, :things => 2)

      r.reload
      r.thing = 42
      r.frozen?
      r.thing.should == 42
    end

  end
end