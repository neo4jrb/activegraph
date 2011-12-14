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
  end

end
