require 'spec_helper'

describe Neo4j::Rails::HasN, :type => :unit do

  without_database

  def create_simple_model(name = nil, inherit_from=Object)
    klass = Class.new(inherit_from) do
      def self._decl_rels
        @_decl_rels ||= {}
      end

      attr_accessor :attr

      def initialize(attr = {})
        @attr = attr
        initialize_relationships
      end

      def wrapper
        self
      end

      include Neo4j::Wrapper::HasN::InstanceMethods
      include Neo4j::Rails::HasN
      include Neo4j::Rails::Relationships
    end
    TempModel.set(klass, name)
  end

  let(:klass) {create_simple_model}
  let(:other_klass) {create_simple_model}

  let(:node) do
    n = klass.new
    n.initialize_relationships
    n
  end

  let(:other) do
    other_klass.new
  end

  describe "has_one(:best_friend)" do
    it "has a best_friend class method for the relationship type" do
      klass.has_one(:best_friend).to(other_klass)
      klass.has_one(:stuff)

      klass.stuff.should == :stuff
      klass.best_friend.should == :"#{klass}#best_friend"
    end
  end

  share_examples_for "has_n(:friends).to(Other)" do
    it "has a friend class method for the relationship type" do
      klass.friends.should == :"#{klass}#friends"
    end

    describe "node.friends.build(:name => 'foo')" do
      it "initialize a node with give properties" do
        f = node.friends.build(:name => 'foo')
        f.should be_kind_of(other_klass)
        f.attr[:name].should == 'foo'
      end
    end

    describe "node.friends.create(:name => 'foo')" do
      it "initialize a node with give properties" do
        other.should_receive(:save)
        other_klass.should_receive(:create).with(:name => 'foo').and_return(other)
        node.friends.create(:name => 'foo')
      end
    end
  end

  describe "has_n(:friends).to(Other)" do
    before { klass.has_n(:friends).to(other_klass) }
    it_should_behave_like "has_n(:friends).to(Other)"
  end

  describe "has_n(:friends).to(Other.to_s)" do
    before { klass.has_n(:friends).to(other_klass.to_s) }
    it_should_behave_like "has_n(:friends).to(Other)"
  end

  share_examples_for "has_n(:known_by).from(Other, :knows)" do

    it "has a friend class method for the relationship type" do
      other_klass.known_by.should == :"#{klass}#knows"
    end

    describe "node.known_by.create(:name => 'foo')" do
      it "initialize a node with give properties" do
        node.should_receive(:save)
        klass.should_receive(:create).with(:name => 'foo').and_return(node)
        other.known_by.create(:name => 'foo')
      end
    end

    describe "node.known_by.build(:name => 'foo')" do
      it "initialize a node with give properties" do
        f = other.known_by.build(:name => 'foo')
        f.should be_kind_of(klass)
        f.attr[:name].should == 'foo'
      end
    end

  end

  describe "has_n(:known_by).from(Other, :knows)" do
    before do
      klass.has_n(:knows).to(other_klass)
      other_klass.has_n(:known_by).from(klass, :knows)
    end

    it_should_behave_like "has_n(:known_by).from(Other, :knows)"
  end

  describe "has_n(:known_by).from(Other.knows)" do
    before do
      klass.has_n(:knows).to(other_klass)
      other_klass.has_n(:known_by).from(klass.knows)
    end

    it_should_behave_like "has_n(:known_by).from(Other, :knows)"
  end

  describe "has_n(:bla).to('MySubKlass')" do
    it "creates a subklass" do
      klass.has_n(:bla).to('MySubKlass123')
      subklass = create_simple_model("MySubKlass123", klass)

      sub_node = subklass.new
      sub_node.should_receive(:save)
      subklass.should_receive(:create).with(:name => 'foo').and_return(sub_node)
      r = node.bla.create(:name => 'foo')
      r.should be_kind_of(subklass)
    end
  end

  describe "has_n :friends" do
    before { klass.has_n :friends }

    describe "node.friends << other" do
      before { node.friends << other }

      context "node.friends" do
        subject { node.friends }
        before { node.stub(:persisted?).and_return(false) }
        it { should include(other) }
        its(:count) { should == 1 }
      end

      describe "write_changed_relationships" do
        it "calls save on start and end nodes" do
          node.stub(:new_record?).and_return(true)
          other.stub(:new_record?).and_return(true)

          node.should_receive(:save).and_return(true)
          other.should_receive(:save).and_return(true)
          node.should_receive(:create_or_updating?).and_return(false)
          other.should_receive(:create_or_updating?).and_return(false)

          node.write_changed_relationships

          new_relationship.start_node.should == node
          new_relationship.end_node.should == other
        end
      end
    end
  end
end
