require 'spec_helper'

describe "IdentityMap", :type => :integration do

  before(:all) do
    Neo4j.db.event_handler.add(Neo4j::IdentityMap)
    @old_identity_map_enabled = Neo4j::IdentityMap.enabled?
    Neo4j::IdentityMap.enabled = true
  end

  after(:all) do
    Neo4j::IdentityMap.enabled = @old_identity_map_enabled
  end

  def reload_entity(wrapper)
    wrapper.class.ancestors.include?(Neo4j::NodeMixin) ? Neo4j::Node.load(wrapper.neo_id) : Neo4j::Relationship.load(wrapper.neo_id)
  end

  share_examples_for "containing the entity" do
    after(:each) { finish_tx }

    it "exist in the identity map" do
      Neo4j::IdentityMap.get(subject._java_entity).should_not be_nil
    end

    it "has the same object id" do
      Neo4j::IdentityMap.get(subject._java_entity).object_id.should == subject.object_id
    end

    context "when loaded" do
      before(:each) { @loaded = reload_entity(subject) }

      it "exist in the identity map" do
        Neo4j::IdentityMap.get(subject._java_entity).should_not be_nil
      end

      it "has the same object id" do
        Neo4j::IdentityMap.get(subject._java_entity).object_id.should == subject.object_id
      end

      it "the loaded object is the same" do
        @loaded.object_id.should == subject.object_id
      end
    end
  end

  share_examples_for "not containing the entity" do
    after(:each) { finish_tx }

    it "does not exist in the identity map" do
      Neo4j::IdentityMap.get(subject._java_entity).should be_nil
    end

    context "when loaded" do
      before(:each) { @loaded = reload_entity(subject) }

      it "exist in the identity map" do
        Neo4j::IdentityMap.get(subject._java_entity).should_not be_nil
      end

      it "has the same object id" do
        Neo4j::IdentityMap.get(subject._java_entity).object_id.should == @loaded.object_id
      end

      it "when loading again it should return the same instance" do
        reload_entity(subject).object_id.should == @loaded.object_id
      end
    end
  end


  before do
    class RailsModelIdentiyTest < Neo4j::Rails::Model
      property :name, :index =>:exact
    end

    class RailsRelationshipIdentiyTest < Neo4j::Rails::Relationship
      property :name, :index => :exact
    end

  end


  context "Created a Rails model but not committed it" do
    before(:each) { new_tx; @instance = RailsModelIdentiyTest.create }
    subject { @instance }
    it_should_behave_like "containing the entity"
  end

  context "Created and committed a Rails model" do
    before(:each) { @instance = RailsModelIdentiyTest.create }
    subject { @instance }
    it_should_behave_like "not containing the entity"
  end


  context "Created a Rails model but not committed it" do
    before(:each) do
      new_tx
      @a = Neo4j::Rails::Model.create(:name => 'a')
      @b = Neo4j::Rails::Model.create(:name => 'b')
      @instance = RailsRelationshipIdentiyTest.create(:foo, @a, @b)
    end
    subject { @instance }
    it_should_behave_like "containing the entity"
  end

  context "Created and committed a Rails model" do
    before(:each) do
      @a = Neo4j::Rails::Model.create(:name => 'a')
      @b = Neo4j::Rails::Model.create(:name => 'b')
      @instance = RailsRelationshipIdentiyTest.create(:foo, @a, @b)
    end
    subject { @instance }
    it_should_behave_like "not containing the entity"
  end

  context "A found none committed rails model" do
    before(:each) do
      new_tx
      Neo4j.ref_node.outgoing(:foobar) << RailsModelIdentiyTest.create(:name => '12345')
      @instance = Neo4j.ref_node.node(:outgoing, :foobar)
    end
    after(:each) { @instance.destroy; finish_tx }

    subject { @instance }
    it_should_behave_like "containing the entity"
  end

  context "A found Rails and committed model" do
    before(:each) do
      RailsModelIdentiyTest.create(:name => '12345') # commits
      @instance = RailsModelIdentiyTest.find_by_name('12345')
    end
    after(:each) { @instance.destroy }

    subject { @instance }
    it_should_behave_like "containing the entity"
  end

  context "after commit" do
    it "should clean the identity map" do
      imap = Neo4j::IdentityMap
      imap.add(Neo4j.ref_node, "thing")
      imap.node_repository.size.should > 0
      new_tx
      Neo4j::Node.new
      #Neo4j.ref_node[:foo] = 'bar'
      finish_tx
      imap.node_repository.size.should == 0
    end
  end

  describe "Neo4j::IdentityMap.without" do
    before(:each) do
      @model = RailsModelIdentiyTest.create
      @node = @model._java_node
    end

    it "should refuse to store wrapped nodes" do
      Neo4j::IdentityMap.without do
        Neo4j::IdentityMap.add(@node, @model)
        Neo4j::IdentityMap.get(@node).should be_nil
      end
    end

    it "should not be enabled" do
      Neo4j::IdentityMap.without do
        Neo4j::IdentityMap.should_not be_enabled
      end
    end

    it "should restore the old value after the block" do
      old = Neo4j::IdentityMap.enabled
      Neo4j::IdentityMap.without do
      end
      Neo4j::IdentityMap.enabled.should == old
    end
  end

  describe "Neo4j::IdentityMap.use" do
    before(:each) do
      @model = RailsModelIdentiyTest.create
      @node = @model._java_node
    end

    it "should allow to store wrapped nodes" do
      Neo4j::IdentityMap.use do
        Neo4j::IdentityMap.add(@node, @model)
        Neo4j::IdentityMap.get(@node).should == @model
        Neo4j::IdentityMap.get(@node).object_id.should == @model.object_id
      end
    end

    it "should be enabled" do
      Neo4j::IdentityMap.use do
        Neo4j::IdentityMap.should be_enabled
      end
    end

    it "should restore the old value after the block" do
      old = Neo4j::IdentityMap.enabled
      Neo4j::IdentityMap.use do
      end
      Neo4j::IdentityMap.enabled.should == old
    end

  end
end