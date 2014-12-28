require 'spec_helper'

describe 'has_one' do

  describe 'has_one(:parent).from(:children)' do
    class HasOneA
      include Neo4j::ActiveNode
      property :name
      has_many :out, :children, model_class: 'HasOneB'
    end

    class HasOneB
      include Neo4j::ActiveNode
      property :name
      has_one :in, :parent, origin: :children, model_class: 'HasOneA'
    end

    context 'with non-persisted node' do
      let(:unsaved_node) { HasOneB.new }
      it 'returns a nil object' do
        expect(unsaved_node.parent).to eq nil
      end

      it 'raises an error when trying to create a relationship' do
        expect { unsaved_node.parent = HasOneA.create }.to raise_error(Neo4j::ActiveNode::HasN::NonPersistedNodeError)
      end
    end

    it 'find the nodes via the has_one accessor' do
      a = HasOneA.create(name: 'a')
      b = HasOneB.create(name: 'b')
      c = HasOneB.create(name: 'c')
      a.children << b
      a.children << c

      c.parent.should == a
      b.parent.should == a
      a.children.to_a.should =~ [b, c]
    end

    it 'can create a relationship via the has_one accessor' do
      a = HasOneA.create(name: 'a')
      b = HasOneB.create(name: 'b')
      b.parent = a
      b.parent.should == a
      a.children.to_a.should == [b]
    end

    it 'can return relationship object via parent_rel' do
      a = HasOneA.create(name: 'a')
      b = HasOneB.create(name: 'b')
      b.parent = a
      rel = b.parent_rel
      rel.other_node(b).should == a
    end

    it 'deletes previous parent relationship' do
      a = HasOneA.create(name: 'a')
      b = HasOneB.create(name: 'b')
      a.children << b
      a.children.to_a.should eq([b])
      b.parent.should eq(a)

      a2 = HasOneA.create(name: 'a2')
      # now it should delete this relationship created above
      b.parent = a2

      b.parent.should eq(a2)
      a2.children.to_a.should eq([b])
    end

    it 'can access relationship via #nodes method' do
      a = HasOneA.create(name: 'a')
      b = HasOneB.create(name: 'b')
      b.parent = a
      b.query_as(:b).match('b<-[:`CHILDREN`]-(r)').pluck(:r).should == [a]
      a.query_as(:a).match('a-[:`CHILDREN`]->(r)').pluck(:r).should == [b]
      #      b.nodes(dir: :incoming, type: HasOneB.parent).to_a.should == [a]
      #      a.nodes(dir: :outgoing, type: HasOneB.parent).to_a.should == [b]
    end
  end

  describe 'has_one(:parent).from(Folder.files)' do
    class Folder1
      include Neo4j::ActiveNode
    end

    class File1
      include Neo4j::ActiveNode
    end

    Folder1.has_many :out, :files, model_class: File1
    File1.has_one :in, :parent, model_class: Folder1, origin: :files

    it 'can access nodes via parent has_one relationship' do
      f1 = Folder1.create
      file1 = File1.create
      file2 = File1.create
      f1.files << file1
      f1.files << file2
      f1.files.to_a.should =~ [file1, file2]
      file1.parent.should == f1
      file2.parent.should == f1
    end
  end

  describe 'callbacks' do
    class CallbackUser
      include Neo4j::ActiveNode

      has_one :out, :best_friend, model_class: self, before: :before_callback
      has_one :in, :best_friend_of, origin: :best_friend, model_class: self, after: :after_callback
      has_one :in, :failing_assoc,  origin: :best_friend, model_class: self, before: :false_before_callback

      def before_callback(other)
      end

      def after_callback(other)
      end

      def false_before_callback(other)
        false
      end
    end

    let(:node1) { CallbackUser.create }
    let(:node2) { CallbackUser.create }

    it 'calls before callback' do
      expect(node1).to receive(:before_callback).with(node2)
      node1.best_friend = node2
    end

    it 'calls after callback' do
      expect(node1).to receive(:after_callback).with(node2)
      node1.best_friend_of = node2
    end

    it 'prevents the relationship from beign created if a before callback returns false' do
      node1.failing_assoc = node2
      expect(node1.failing_assoc).to be_nil
    end
  end
end
