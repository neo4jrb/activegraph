module Regressions
  require 'spec_helper'

  class Actor < Neo4j::Rails::Model
    rule(:was_born) { |n| !n[:born].nil? }
  end

  describe "Issue 178, make sure the rule function is executed when node are deleted" do
    it "has a correct count" do
      Actor.create :name => "First"
      Actor.all.count.should == 1
      Actor.all.to_a.count.should == 1
      Actor.destroy_all
      Actor.all.count.should == 0
      Actor.all.to_a.count.should == 0
    end
  end
end