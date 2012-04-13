require 'spec_helper'

describe Neo4j::Rails::Attributes, :type => :unit do

  without_database

  let(:new_node) { MockNode.new }
  let(:new_model) { klass.new }
  let(:saved_model) do
    node = klass.new
    node.save
    node
  end

  module MyConverter
    def to_java(v)
      "Java:#{v}"
    end

    def to_ruby(v)
      "Ruby:#{v}"
    end

    extend self
  end

  let(:klass) do
    k = Class.new do
      include Neo4j::NodeMixin
      include ActiveModel::Dirty
      include Neo4j::Rails::Persistence
      include Neo4j::Rails::NodePersistence
      include Neo4j::Rails::Attributes
      include Neo4j::Rails::Relationships
      property :name, :converter => MyConverter
      property :since, :type => Date
    end
    TempModel.set(k)
  end

  let(:subklass) do
    k = Class.new(klass)
    klass.inherited(k)
    TempModel.set(k)
  end

  before do
    klass.stub(:load_entity).and_return(new_model)
  end

  describe "attribute_defaults" do
    it "has a class method that by default returns an empty hash" do
      klass.attribute_defaults.should == {}
    end

    it "has a class method that by default returns an empty hash" do
      subklass.attribute_defaults.should == {}
      subklass.new.attribute_defaults.should == {} #read_local_property(:thing)
    end

    it "has a class method that by default returns an empty hash" do
      new_model.attribute_defaults.should == {}
    end

  end

  describe "inheritance of attributes" do
    it "should inherit base class attributes" do
      klass.new.attribute_names.should == %w[name since]
      subklass.new.attribute_names.should == %w[name since]
    end
  end

  describe "converters" do
    let(:today) { Date.today }
    subject do
      n = klass.new
      n.since = today
      n
    end

    context "when new" do
      it "uses the converter type" do
        subject.since.should == today
      end

      it "can use custom converter" do
        subject.name.should == "Ruby:"
      end

      context "for a subclass" do
        subject do
          n = subklass.new
          n.since = today
          n
        end
        it "uses the converter type" do
          subject.since.should == today
        end

        it "can use custom converter" do
          subject.name.should == "Ruby:"
        end
      end
    end

    context "when saved" do
      before { subject.save }

      it "should store the convertered value to the database" do
        new_node[:since].should == Time.utc(today.year, today.month, today.day).to_i
      end

      it "attribute value is of specified type" do
        subject.since.should == today
      end

      it "can save using the custom converter" do
        subject.name = "bla"
        subject.name.should == "Ruby:Java:bla"
      end

    end

  end


  describe "read_attribute" do
    it "returns nil if attribute does not exist" do
      saved_model.read_attribute(:kalle).should be_nil
    end

    it "returns the property value" do
      new_node[:kalle] = "bla"
      saved_model.read_attribute(:kalle).should == "bla"
    end

  end

  describe "property_changed?" do
    it "is true if a property has changed" do
      new_model.property_changed?.should be_false
      new_model[:bla] = 42
      new_model.property_changed?.should be_true
    end

    it "is false when node has been saved" do
      new_model[:bla] = 42
      new_model.save!
      new_model.property_changed?.should be_false
    end
  end

  describe "update_attributes" do

    it "update properties and saves the model" do
      new_model.update_attributes(:kalle => 'foo')
      new_model[:kalle].should == 'foo'
      new_model.should be_persisted
    end
  end

  describe "default" do
    it "uses the default value" do
      klass.property :age, :default => 42
      new_model.age.should == 42
      saved_model.age.should == 42
    end
  end

end

