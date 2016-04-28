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

    # See unpersisted_association_spec.rb for additional tests related to this
    context 'with non-persisted node' do
      let(:unsaved_node) { HasOneB.new }

      it 'returns a nil object' do
        expect(unsaved_node.parent).to eq nil
      end
    end

    it 'find the nodes via the has_one accessor' do
      a = HasOneA.create(name: 'a')
      b = HasOneB.create(name: 'b')
      c = HasOneB.create(name: 'c')
      a.children << b
      a.children << c

      expect(c.parent).to eq(a)
      expect(b.parent).to eq(a)
      expect(a.children.to_a).to match_array([b, c])
    end

    it 'caches the result of has_one accessor' do
      a = HasOneA.create(name: 'a')
      b = HasOneB.create(name: 'b')
      a.children << b

      b = HasOneB.find(b.id)

      expect_queries(1) do
        expect(b.parent).to eq(a)
        expect(b.parent).to eq(a)
      end
    end

    it 'clears the cached result of a has_one accessor on reload' do
      a = HasOneA.create(name: 'a')
      b = HasOneB.create(name: 'b')
      a.children << b

      b = HasOneB.find(b.id)

      expect_queries(1) do
        expect(b.parent).to eq(a)
        expect(b.parent).to eq(a)
      end

      b.reload

      expect_queries(1) do
        expect(b.parent).to eq(a)
        expect(b.parent).to eq(a)
      end
    end

    it 'can create a relationship via the has_one accessor' do
      a = HasOneA.create(name: 'a')
      b = HasOneB.create(name: 'b')
      b.parent = a
      expect(b.parent).to eq(a)
      expect(a.children.to_a).to eq([b])
    end

    it 'can return relationship object via parent.rel' do
      a = HasOneA.create(name: 'a')
      b = HasOneB.create(name: 'b')
      b.parent = a
      rel = b.parent.rel
      expect(rel.other_node(b)).to eq(a)
    end

    it 'deletes previous parent relationship' do
      a = HasOneA.create(name: 'a')
      b = HasOneB.create(name: 'b')
      a.children << b
      expect(a.children.to_a).to eq([b])
      expect(b.parent).to eq(a)

      a2 = HasOneA.create(name: 'a2')
      # now it should delete this relationship created above
      b.parent = a2

      expect(b.parent).to eq(a2)
      expect(a2.children.to_a).to eq([b])
    end

    it 'can access relationship via #nodes method' do
      a = HasOneA.create(name: 'a')
      b = HasOneB.create(name: 'b')
      b.parent = a
      expect(b.query_as(:b).match('(b)<-[:`CHILDREN`]-(r)').pluck(:r)).to eq([a])
      expect(a.query_as(:a).match('(a)-[:`CHILDREN`]->(r)').pluck(:r)).to eq([b])
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
      expect(f1.files.to_a).to match_array([file1, file2])
      expect(file1.parent).to eq(f1)
      expect(file2.parent).to eq(f1)
    end
  end

  describe 'has_one(:manager).from(:subordinates)' do
    before(:each) do
      stub_active_node_class('Person') do
        has_many :out, :subordinates, type: nil, model_class: self
        has_one :in, :manager, model_class: self, origin: :subordinates
      end
    end

    let(:big_boss) { Person.create }
    let(:manager) { Person.create }
    let(:employee) { Person.create }

    context 'with variable-length relationships' do
      before do
        big_boss.subordinates << manager
        manager.subordinates << employee
      end

      it 'finds the chain of command' do
        expect(employee.manager(:p, :r, rel_length: {min: 0}).to_a).to match_array([employee, manager, big_boss])
      end

      it "finds the employee's superiors" do
        expect(employee.manager(:p, :r, rel_length: :any).to_a).to match_array([manager, big_boss])
      end

      it 'finds a specific superior in the chain of command' do
        expect(employee.manager(:p, :r, rel_length: 1)).to eq(manager)
        expect(employee.manager(:p, :r, rel_length: 2)).to eq(big_boss)
      end

      it 'finds parts of the chain of command using a range' do
        expect(employee.manager(:p, :r, rel_length: (0..1)).to_a).to match_array([employee, manager])
      end

      it 'finds parts of the chain of command using a hash' do
        expect(employee.manager(:p, :r, rel_length: {min: 1, max: 3}).to_a).to match_array([manager, big_boss])
      end
    end
  end

  describe 'association "getter" options' do
    before(:each) do
      stub_active_node_class('Person') do
        has_many :out, :subordinates, type: nil, model_class: self
        has_one :in, :manager, model_class: self, origin: :subordinates
      end
    end

    let(:manager) { Person.create }
    let(:employee) { Person.create }

    it 'allows passing only a hash of options when naming node/rel is not needed' do
      manager.subordinates << employee
      expect(employee.manager(rel_length: 1)).to eq(manager)
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

  describe 'id methods' do
    before(:each) do
      stub_active_node_class('Post') do
        has_many :in, :comments, type: :COMMENTS_ON
      end

      stub_active_node_class('Comment') do
        has_one :out, :post, type: :COMMENTS_ON
      end
    end

    let(:post) { Post.create }
    let(:comment) { Comment.create }
    before(:each) { comment.post = post }

    it 'returns various IDs for associations' do
      expect(comment.post_id).to eq(post.id)
      expect(comment.post_neo_id).to eq(post.neo_id)
    end
  end
end
