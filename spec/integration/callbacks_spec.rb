require 'spec_helper'

module Neo4j
  module Rails
    class CallbacksTestModel < Neo4j::RailsNode
      property :name, :desc

      after_initialize :set_desc
      before_validation :downcase_name

      private
      def downcase_name
        self.name.downcase!
      end

      def set_desc
        self.desc ||= self.name
      end
    end

    describe Callbacks, :type => :integration do
      it "should be possible to define a before_validation callback and have it triggered" do
        m = CallbacksTestModel.new(:name => "Test")
        m.name.should == "Test"
        m.valid?
        m.name.should == "test"
      end

      it "should have after_intialize callback triggered" do
        m = CallbacksTestModel.new(:name => "Test")
        m.desc.should == "Test"
      end
    end
  end
end
