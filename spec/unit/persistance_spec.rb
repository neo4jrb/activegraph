require 'spec_helper'

# Neo4j::Rails::Relationship
# Neo4j::Rails::Model

# Neo4j::Rails::Model
# Neo4j::Rails::Relationship

# Neo4j::Rails::ModelMixin
# Neo4j::Rails::RelationshipMixin

describe Neo4j::Rails::Persistence, :type => :unit do

  without_database

  let(:new_node) { MockNode.new }
  let(:new_model) { klass.new }
  let(:saved_model) do
    node = klass.new
    node.save
    node
  end

  let(:klass) do
    Class.new do
      include Neo4j::NodeMixin
      include ActiveModel::Dirty # track changes to attributes
      include Neo4j::Rails::Identity
      include Neo4j::Rails::Persistence
      include Neo4j::Rails::NodePersistence
      include Neo4j::Rails::Attributes
      include Neo4j::Rails::Relationships

      property :name
    end
  end

  before do
    klass.stub(:load_entity).and_return(new_model)
  end

  describe "new" do
    subject do
      klass.new
    end

    its(:persisted?) { should be_false }
    it "should yield" do
      k = klass.new do
        self.name = "baaz"
      end
      k.name.should == 'baaz'
    end
  end

  describe "save" do
    before do
      @n = klass.new
      @n.save
      klass.stub(:load_entity).and_return(@n)
    end

    subject { @n }

    its(:_java_node) { should == new_node }
    its(:persisted?) { should be_true }
  end

  describe "update_attribute" do
    context "when new" do
      subject { new_model }
      it "sets props" do
        subject.update_attribute(:name, 'foo')
        subject[:name].should == 'foo'
      end
    end

    context "when saved" do
      subject { saved_model }

      it "sets props" do
        subject.update_attribute(:name, 'foo')
        subject[:name].should == 'foo'
      end
    end
  end

  describe "destroy" do
    context "when new" do
      subject { new_model }
      it "destroys" do
        subject.destroy
        subject.should be_destroyed
      end
    end

    context "when saved" do
      subject { saved_model }
      it "destroys" do
        subject.should_receive(:del)
        subject.destroy
        subject.should be_destroyed
      end
    end
  end

  describe "update_attributes" do
    context "when new" do
      subject { new_model }
      it "sets properties" do
        subject.update_attributes(:name => 'kalle')
        subject[:name].should == 'kalle'
      end
    end

    context "when saved" do
      subject { saved_model }
      it "sets properties" do
        subject.update_attributes(:name => 'kalle')
        subject[:name].should == 'kalle'
      end
    end

  end

  describe "reload" do
    context "when new" do
      subject { new_model }
      it "raise an exception" do
        lambda { subject.reload }.should_not raise_error
      end
    end

    context "when saved" do
      subject { saved_model }
      it "reloads it and set the attributes" do
        subject.should_receive(:clear_composition_cache)
        node = Struct.new(:attributes).new(:name => 'bla')
        subject.class.stub(:load_entity).and_return(node)
        subject.reload
        subject[:name].should == 'bla'
      end
    end
  end

end