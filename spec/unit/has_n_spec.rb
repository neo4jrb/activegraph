require 'spec_helper'

describe Neo4j::Rails::HasN, :type => :unit do

  without_database

  let(:klass) do
    Class.new do
      def self.to_s
        "Klass"
      end

      def self._decl_rels
        @_decl_rels ||= {}
      end

      def wrapper
        self
      end
      include Neo4j::Wrapper::HasN::InstanceMethods
      include Neo4j::Rails::HasN
      include Neo4j::Rails::Relationships
    end
  end

  let(:other_klass) do
    Class.new do
      def self.to_s
        "OtherKlass"
      end

      attr_accessor :attr

      def initialize(attr = {})
        @attr = attr
        initialize_relationships
      end

      def self._decl_rels
        @_decl_rels ||= {}
      end

      def wrapper
        self
      end
      include Neo4j::Wrapper::HasN::InstanceMethods
      include Neo4j::Rails::HasN
      include Neo4j::Rails::Relationships
    end
  end

  let(:node) do
    n = klass.new
    n.initialize_relationships
    n
  end

  let(:other) do
    other_klass.new
  end

  describe "has_n(:friends).to(Other)" do
    before { klass.has_n(:friends).to(other_klass) }

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

  describe "has_n :friends" do
    before { klass.has_n :friends }

    describe "node.friends << other" do
      before { node.friends << other }

      context "node.friends" do
        subject { node.friends}
        before { node.stub(:persisted?).and_return(false)}
        it { should include(other)}
        its(:count) { should == 1}
      end

      describe "write_changed_relationships" do
        it "calls save on start and end nodes" do
          node.stub(:new_record?).and_return(true)
          other.stub(:new_record?).and_return(true)

          node.should_receive(:save).and_return(true)
          other.should_receive(:save).and_return(true)
          node.write_changed_relationships

          new_relationship.start_node.should == node
          new_relationship.end_node.should == other
        end
      end
    end
  end
end
