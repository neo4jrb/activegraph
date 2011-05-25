require File.join(File.dirname(__FILE__), '..', 'spec_helper')

module Neo4j
  module Rails
    class CallbacksTestModel < Neo4j::Rails::Model
      property :name
      
      before_validation :downcase_name
      
      private
      def downcase_name
        self.name.downcase!
      end
    end

    describe Callbacks do
      it "should be possible to define a before_validation callback and have it triggered" do
        m = CallbacksTestModel.new(:name => "Test")
        m.name.should == "Test"
        m.valid?
        m.name.should == "test"
      end
    end
  end
end
