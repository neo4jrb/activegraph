require File.join(File.dirname(__FILE__), '..', 'spec_helper')

module Neo4j
  module Rails
    class AttributesTestModel < Neo4j::Rails::Model
      property :name
      property :number_property, :type => :float
      property :foo
      property :defaulty, :type => Fixnum, :default => 10
      validates :number_property, :numericality => { :allow_nil => true }

      def foo=(f)
        self.name = f + 'changed'
      end

    end

    describe Attributes do
      subject do
        AttributesTestModel.create!(:name => "Test")
        AttributesTestModel.last
      end


      it "should be possible to override a declared property" do
        # this is done both by devise and I think carrierwave
        # http://neo4j.lighthouseapp.com/projects/15548-neo4j/tickets/201-neo4jcarrierwave-neo4j-file-upload-error#ticket-201-2
        subject.update_attributes(:foo =>'abc')
        subject.save!
        subject.name.should == 'abcchanged'
      end

      it "should be possible to set attribute as nil before accessing it in a freshly loaded model" do
        subject.name = nil
        subject.name.should be_nil
      end

      describe "property_before_type_cast" do
        it "should retain value before type convertion for validations" do
          subject.number_property = "abc"

          subject.should be_invalid
          subject.errors[:number_property].should include("is not a number")
          subject.number_property_before_type_cast.should == "abc"
          subject.number_property.should == 0
        end

        it "should not be included in attributes list" do
          subject.number_property = "123"

          subject.attributes.should_not include("number_property_before_type_cast")
          subject.attribute_names.should_not include("number_property_before_type_cast")
        end

        it "should not be tracked as changed attribute" do
          subject.number_property = "123"

          subject.changed_attributes.should_not include("number_property_before_type_cast")
        end

        it "should not saved as node property" do
          subject.number_property = "123"
          subject.save!

          subject._java_node.property?(:number_property_before_type_cast).should be_false
          AttributesTestModel.find(subject.id)[:number_property_before_type_cast].should be_nil
        end

        it "should have valid default" do
          subject.defaulty.should == 10
        end

        it "should return default for no value" do
          subject.defaulty = nil
          subject.defaulty.should == 10
        end

      end
    end
  end
end
