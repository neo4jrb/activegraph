module Regressions
  require 'spec_helper'

  describe "Issue 172, Save callbacks fire once for every outgoing has_one node" do
    it "should only call save callback once" do
      a = Neo4j::Rails::Model.new
      b = Neo4j::Rails::Model.new

      klass = create_model do
        has_one(:target1)
        has_one(:target2)
        after_save :foobar

        def foobar
        end
      end

      c = klass.new
      c.should_receive(:foobar).once
      c.target1 = a
      c.target2 = b
      c.save
    end

  end

end
