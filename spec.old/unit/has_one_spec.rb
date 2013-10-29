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

  describe "has_one(:best_friend).to(Other)" do
    before { klass.has_one(:best_friend).to(other_klass) }

    describe "node.build_best_friend(:name => 'foo')" do
      it "initialize a node with give properties" do
        node.stub(:persisted?).and_return(false)
        f = node.build_best_friend(:name => 'foo')
        f.should be_kind_of(other_klass)
        f.attr[:name].should == 'foo'
      end
    end

    describe "node.create_best_friend(:name => 'foo')" do
      it "initialize a node with give properties" do
        other.should_receive(:save)
        other_klass.should_receive(:create).with(:name => 'foo').and_return(other)
        node.create_best_friend(:name => 'foo')
      end
    end

    describe "node.create_best_friend!(:name => 'foo')" do
      it "initialize a node with give properties" do
        other.should_receive(:save!)
        other_klass.should_receive(:create).with(:name => 'foo').and_return(other)
        node.create_best_friend!(:name => 'foo')
      end
    end

  end

  describe "has_one(:best_friend).from(Other, :knows)" do
    before do
      other_klass.has_n(:knows)
      klass.has_one(:best_friend).from(other_klass, :knows)
    end

    describe "node.build_best_friend(:name => 'foo')" do
      it "initialize a node with give properties" do
        node.stub(:persisted?).and_return(false)
        f = node.build_best_friend(:name => 'foo')
        f.should be_kind_of(other_klass)
        f.attr[:name].should == 'foo'
      end
    end

    describe "node.create_best_friend(:name => 'foo')" do
      it "initialize a node with give properties" do
        other.should_receive(:save)
        other_klass.should_receive(:create).with(:name => 'foo').and_return(other)
        node.create_best_friend(:name => 'foo')
      end
    end

    describe "node.create_best_friend!(:name => 'foo')" do
      it "initialize a node with give properties" do
        other.should_receive(:save!)
        other_klass.should_receive(:create).with(:name => 'foo').and_return(other)
        node.create_best_friend!(:name => 'foo')
      end
    end

  end

  describe "has_one :best_friend" do
    before { klass.has_one :best_friend }

    describe "node.best_friend = other" do
      before do
        node.stub(:persisted?).and_return(false)
        other.stub(:persisted?).and_return(false)
        node.best_friend = other
      end

      context "node.best_friend" do
        before { node.stub(:_java_entity).and_return(nil) }
        subject { node.best_friend }
        it { should == other }
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

      it "should not store the relationship twice" do
        node.stub(:new_record?).and_return(true)
        other.stub(:new_record?).and_return(true)

        node.should_not_receive(:save)
        other.should_not_receive(:save)
        node.should_receive(:create_or_updating?).and_return(true)
        other.should_receive(:create_or_updating?).and_return(true)

        node.write_changed_relationships
      end
    end
  end
end
