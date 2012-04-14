require 'spec_helper'

describe Neo4j::Rails::Model, :type => :unit do

  without_database

  let(:klass) { create_model }


  describe "save" do
    it "sets the _java_entity" do
      klass.create._java_entity.should == new_node
    end
  end

  describe "property with default values" do
    it "uses the default value" do
      #klass.stub(:load_entity).and_return(new_model)
      klass.property :age, :default => 42
      klass.new.age.should == 42
      n = klass.create
      n.age.should == 42
      n._java_entity[:age].should == 42
    end
  end

  describe "has_n" do
    before do
      klass.has_n :friends
    end

    describe "<<" do
      context "when not saved" do
        it "add a relationship" do
          a = klass.new
          b = klass.new
          a.friends << b
          a.friends.count.should == 1
        end
      end

      context "when nodes are saved" do
        it "add a relationship" do
          java_node_a = MockNode.new
          java_node_b = MockNode.new
          a = klass.new.mock_save(java_node_a)
          b = klass.new.mock_save(java_node_b)
          a.friends << b

          java_node_a.should_receive(:_rels).with(:outgoing, :friends).and_return([])
          a.friends.count.should == 1
        end
      end

      context "when saving a node with unpersisted start end end nodes" do
        it "reads the relationship from neo4j" do
          a = klass.new
          b = klass.new
          a.friends << b

          a.save
          a.should_receive(:persisted?).and_return(true)
          # since it is persisted it will read from the database, hence using the _rels method
          a.should_receive(:_rels).with(:outgoing, :friends).and_return([b])
          a.friends.count.should == 1
        end
      end

      context "when saving a node with persisted end and start nodes" do
        it "create a new relationship" do
          a = klass.new.mock_save(java_node_a = MockNode.new)
          b = klass.new.mock_save(java_node_b = MockNode.new)
          a.friends << b

          Neo4j::Relationship.should_receive(:new).with(:friends, java_node_a, java_node_b).and_return(MockRelationship.new(:friends, java_node_a, java_node_b))
          a.save
          java_node_a.should_receive(:_rels).with(:outgoing, :friends).and_return([b])
          a.friends.count.should == 1
        end
      end

    end
  end
end

