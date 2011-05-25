require File.join(File.dirname(__FILE__), '..', 'spec_helper')

module Neo4j
  module Rails
    class AttributesTestModel < Neo4j::Rails::Model
      property :name
    end

    describe Attributes do
      subject do
        AttributesTestModel.create!(:name => "Test")
        AttributesTestModel.last
      end
      
      it "should be possible to set attribute as nil before accessing it in a freshly loaded model" do
        subject.name = nil
        subject.name.should be_nil
      end
    end
  end
end
