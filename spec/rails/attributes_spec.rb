require File.join(File.dirname(__FILE__), '..', 'spec_helper')

module Neo4j
  module Rails
    class AttributesTestModel < Neo4j::Rails::Model
      property :name
      property :float_property, type => :float, :default => 0

      validates :float_property, :numericality => true
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

      it "should retain value before_type_cast for validations" do
         subject.float_property = "abc"

         subject.should be_invalid
         subject.errors[:float_property].should include("is not a number")
         subject.float_property_before_type_cast.should == "abc"
       end

      it "should not save before_type_cast values as node property" do
         subject.float_property = "123"
         subject.save!

         subject._java_node.property?(:float_property_before_type_cast).should be_false
         AttributesTestModel.find(subject.id)[:float_property_before_type_cast].should be_nil
       end

       it "should not include property before_type_cast" do
         subject.float_property = "123"

         subject.attribute_names.should_not include("float_property_before_type_cast")
         subject.attributes.should_not include("float_property_before_type_cast")
         subject.changed_attributes.should_not include("float_property_before_type_cast")
       end
    end
  end
end
