require 'spec_helper'

describe 'has_one' do
  before(:each) do
    delete_db
    clear_model_memory_caches
  end

  describe 'has_one(:parent).from(:children)' do
    before(:each) do
      stub_active_node_class('HasOneA') do
        property :name
        has_many :out, :children, type: nil, model_class: 'HasOneB'
      end

      stub_active_node_class('HasOneB') do
        property :name
        has_one :in, :parent, origin: :children, model_class: 'HasOneA'
      end
    end

    context 'with non-persisted node' do
      let(:unsaved_node) { HasOneB.new }
      it 'returns a nil object' do
        expect(unsaved_node.parent).to eq nil
      end

      it 'raises an error when trying to create a relationship' do
        expect { unsaved_node.parent = HasOneA.create }.to raise_error(Neo4j::ActiveNode::HasN::NonPersistedNodeError)
      end

      context 'with enabled auto-saving' do
        let_config(:autosave_on_assignment) { true }

        it 'saves the node' do
          expect { unsaved_node.parent = HasOneA.create }.to change(unsaved_node, :persisted?).from(false).to(true)
        end

        it 'saves the associated node' do
          other_node = HasOneA.new
          expect { unsaved_node.parent = other_node }.to change(other_node, :persisted?).from(false).to(true)
        end
      end
    end

    it 'find the nodes via the has_one accessor' do
      a = HasOneA.create(name: 'a')
      b = HasOneB.create(name: 'b')
      c = HasOneB.create(name: 'c')
      a.children << b
      a.children << c

      c.parent.should eq(a)
      b.parent.should eq(a)
      a.children.to_a.should =~ [b, c]
    end

    it 'can create a relationship via the has_one accessor' do
      a = HasOneA.create(name: 'a')
      b = HasOneB.create(name: 'b')
      b.parent = a
      b.parent.should eq(a)
      a.children.to_a.should eq([b])
    end

    it 'can return relationship object via parent.rel' do
      a = HasOneA.create(name: 'a')
      b = HasOneB.create(name: 'b')
      b.parent = a
      rel = b.parent.rel
      rel.other_node(b).should eq(a)
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
      b.query_as(:b).match('b<-[:`CHILDREN`]-(r)').pluck(:r).should eq([a])
      a.query_as(:a).match('a-[:`CHILDREN`]->(r)').pluck(:r).should eq([b])
      #      b.nodes(dir: :incoming, type: HasOneB.parent).to_a.should eq([a])
      #      a.nodes(dir: :outgoing, type: HasOneB.parent).to_a.should eq([b])
    end
  end

  describe 'has_one(:parent).from(Folder.files)' do
    before(:each) do
      stub_active_node_class('Folder1') do
        has_many :out, :files, type: nil, model_class: 'File1'
      end

      stub_active_node_class('File1') do
        has_one :in, :parent, model_class: 'Folder1', origin: :files
      end
    end

    it 'can access nodes via parent has_one relationship' do
      f1 = Folder1.create
      file1 = File1.create
      file2 = File1.create
      f1.files << file1
      f1.files << file2
      f1.files.to_a.should =~ [file1, file2]
      file1.parent.should eq(f1)
      file2.parent.should eq(f1)
    end
  end

  describe 'callbacks' do
    before(:each) do
      stub_active_node_class('CallbackUser') do
        has_one :out, :best_friend, type: nil, model_class: 'CallbackUser', before: :before_callback
        has_one :in, :best_friend_of, origin: :best_friend, model_class: 'CallbackUser', after: :after_callback
        has_one :in, :failing_assoc,  origin: :best_friend, model_class: 'CallbackUser', before: :false_before_callback

        def before_callback(_other)
        end

        def after_callback(_other)
        end

        def false_before_callback(_other)
          false
        end
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
