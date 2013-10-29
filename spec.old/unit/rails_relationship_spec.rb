require 'spec_helper'


describe Neo4j::Rails::Model, :type => :unit do

  without_database

  let(:start_java_node) { MockNode.new }
  let(:end_java_node) { MockNode.new }
  let(:start_node) { create_model.new }
  let(:end_node) { create_model.new }

  let(:rel_klass) do
    Class.new do
      include Neo4j::RelationshipMixin
      include Neo4j::Rails::Identity
      include Neo4j::Rails::Persistence # handles how to save, create and update the model
      include Neo4j::Rails::RelationshipPersistence # handles how to save, create and update the model
      include Neo4j::Rails::Attributes # handles how to save and retrieve attributes
    end
  end

  describe "new" do
    subject do
      rel_klass.new(:friends, start_node, end_node)
    end

    its(:start_node) { should == start_node }
    its(:end_node) { should == end_node }
    its(:rel_type) { should == :friends }
    its(:persisted?) { should be_false }
    its(:destroyed?) { should be_false }
    its(:new_record?) { should be_true }
    its(:frozen?) { should be_false }
  end

  describe "create" do
    before do
      start_node.mock_save(start_java_node)
      end_node.mock_save(end_java_node)
      Neo4j::Relationship.stub(:new).with(:friends, start_java_node, end_java_node).and_return(MockRelationship.new(:friends, start_java_node, end_java_node))
      rel_klass.stub(:load_entity) do |id|
        "Loaded entity #{id}"
      end
    end

    subject do
      rel_klass.create(:friends, start_node, end_node)
    end

    its(:start_node) { should == start_node }
    its(:end_node) { should == end_node }
    its(:rel_type) { should == :friends }
    its(:persisted?) { should be_true }
    its(:destroyed?) { should be_false }
    its(:new_record?) { should be_false }
    describe "frozen?" do
      it "reloads the node and returns false" do
        subject.should_receive(:freeze_if_deleted).and_return(true)
        subject.frozen?.should be_false
      end
    end
  end

end

