require File.join(File.dirname(__FILE__), 'spec_helper')

describe Neo4j::Load do
  subject do
    Class.new do
      include Neo4j::Load
    end.new
  end

  describe "#to_class" do
    it "should return namespaced constant" do
      subject.to_class('Neo4j::Load').should == ::Neo4j::Load
    end

    it "should return global constant" do
      subject.to_class('Neo4j').should == ::Neo4j
    end

    context "with global constant" do
      before do
        @previous = defined?(::Property) ? ::Property : nil
        class Property; end
      end
      after do
        ::Property == @previous # TODO: Undefine instead of setting to nil
      end
      it "should resolve global Property constant" do
        subject.to_class("Property").should == ::Property
      end
    end
  end

end
