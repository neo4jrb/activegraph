require 'spec_helper'

describe Neo4j::Rails::Finders, :type => :unit do

  without_database

  let(:new_node) { MockNode.new }
  let(:new_model) { klass.new }
  let(:saved_model) { klass.create }
  let(:klass) do
    create_node_mixin do
      include ActiveModel::Dirty # track changes to attributes
      include Neo4j::Rails::Persistence
      include Neo4j::Rails::NodePersistence

      include Neo4j::Rails::Attributes
      include Neo4j::Rails::Relationships
      include Neo4j::Rails::Validations
      include Neo4j::Rails::Finders

      property :desc, :index => :exact
    end
  end

  before do
    klass.stub(:load_entity).and_return(new_model)
  end

  describe "all" do
    it "calls _all" do
      klass.should_receive(:_all).and_return(42)
      klass.all.should == 42
    end
  end

  describe "last" do
    it "returns the last item from _all" do
      klass.should_receive(:_all).twice.and_return([1,2,3])
      klass.last.should == 3
    end
  end

  describe "find_by_desc" do
    it "uses the _indexer find method" do
      klass._indexer.should_receive(:find).with("desc: \"bla\"").and_return([11,22])
      klass.find_by_desc('bla').should == 11
    end
  end

  describe "find with block" do
    it "allows block" do
      r = []
      klass._indexer.should_receive(:find).with("name: bla").and_yield("HEJ")
      klass.find('name: bla') {|q| r << q}
      r.first.should == "HEJ"
      Neo4j::Core::Index::Indexer
    end
  end

  describe "all_by_desc" do
    it "uses the _indexer find method" do
      klass._indexer.should_receive(:find).with("desc: \"bla\"").and_return([11,22])
      klass.all_by_desc('bla').should == [11,22]
    end
  end

end
