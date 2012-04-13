require 'spec_helper'

describe Neo4j::Rails::Persistence, :type => :unit do

  without_database

  let(:new_node) { MockNode.new }
  let(:new_model) { klass.new }
  let(:saved_model) { klass.create }
  let(:klass) do
    create_node_mixin do
      include ActiveModel::Dirty # track changes to attributes
      include Neo4j::Rails::Identity
      include Neo4j::Rails::Persistence
      include Neo4j::Rails::NodePersistence
      include Neo4j::Rails::Attributes
      include Neo4j::Rails::Validations
      include Neo4j::Rails::Finders
      include Neo4j::Rails::Relationships

      property :desc
    end
  end

  before do
    klass.stub(:load_entity).and_return(new_model)
  end

  describe "valid?" do
    describe "presence => true" do
      it "valid? == true only if property exists" do
        klass.validates :desc, :presence => true
        new_model.valid?.should be_false
        new_model[:desc] = 'bar'
        new_model.valid?.should be_true
        new_model[:desc] = nil
        new_model.valid?.should be_false
        new_model.desc = "hej"
        new_model.valid?.should be_true
      end
    end
  end

  describe "validates :terms_of_service, :acceptance => true" do
    it "valid? == true only if property exists" do
      klass.validates_acceptance_of :terms_of_service
      new_model.terms_of_service = "no thanks"
      new_model.valid?.should be_false
      new_model.terms_of_service = '1'
      new_model.valid?.should be_true
    end

  end

  describe "validates_uniqueness_of" do
    it "only true if it does not exist" do
      klass._indexer.should_receive(:find).with('things: ""').and_return([])
      klass.property :things, :index => :exact
      klass.validates_uniqueness_of :things
      new_model.valid?.should be_true
    end

    it "only false if it does not exist" do
      klass._indexer.should_receive(:find).with('things: "123"').and_return([Struct.new(:id, :things).new("52", 123)])
      klass.property :things, :index => :exact
      klass.validates_uniqueness_of :things
      new_model.things = 123
      new_model.valid?.should be_false
    end

  end
end

