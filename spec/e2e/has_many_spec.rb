describe 'has_many' do
  before(:each) do
    clear_model_memory_caches
    delete_db

    stub_active_node_class('Person') do
      property :name

      has_many :both, :friends, model_class: false, type: nil
      has_many :out, :knows, model_class: 'Person', type: nil
      has_many :in, :knows_me, origin: :knows, model_class: 'Person'
    end
  end

  let(:node) { Person.create }
  let(:friend1) { Person.create }
  let(:friend2) { Person.create }

  describe 'association?' do
    context 'with a present association' do
      subject { Person.association?(:friends) }
      it { is_expected.to be_truthy }
    end

    context 'with a missing association' do
      subject { Person.association?(:fooz) }
      it { is_expected.to be_falsey }
    end
  end

  describe 'associations_keys' do
    subject { Person.associations_keys }
    it { is_expected.to include(:friends, :knows, :knows_me) }
  end

  # See unpersisted_association_spec.rb for more related tests
  describe 'non-persisted node' do
    let(:unsaved_node) { Person.new }
    it 'returns an empty array' do
      expect(unsaved_node.friends).to eq []
    end
  end

  describe 'unique: :none' do
    before { Person.reflect_on_association(:knows).association.instance_variable_set(:@unique, :none) }
    after do
      Person.reflect_on_association(:knows).association.instance_variable_set(:@unique, false)
      [friend1, friend2].each(&:destroy)
    end

    it 'only creates one relationship between two nodes' do
      expect(friend1.knows.count).to eq 0
      friend1.knows << friend2
      expect(friend1.knows.count).to eq 1
      friend1.knows << friend2
      expect(friend1.knows.count).to eq 1
    end

    it 'is respected with an association using origin' do
      expect(friend1.knows.count).to eq 0
      friend2.knows_me << friend1
      expect(friend1.knows.count).to eq 1
      friend2.knows_me << friend1
      expect(friend1.knows.count).to eq 1
    end
  end

  describe 'rel_type' do
    it 'creates the correct type' do
      node.friends << friend1
      r = node.rel
      expect(r.rel_type).to eq(:FRIENDS)
    end

    it 'creates the correct type' do
      node.knows << friend1
      r = node.rel
      expect(r.rel_type).to eq(:KNOWS)
    end

    it 'creates correct incoming relationship' do
      node.knows_me << friend1
      expect(friend1.rel(dir: :outgoing).rel_type).to eq(:KNOWS)
      expect(node.rel(dir: :incoming).rel_type).to eq(:KNOWS)
    end
  end

  it 'access nodes via declared has_n method' do
    expect(node.friends.to_a).to eq([])
    expect(node.friends.any?).to be false

    node.friends << friend1
    expect(node.friends.to_a).to eq([friend1])
  end

  it 'access relationships via declared has_n method' do
    expect(node.friends.rels.to_a).to eq([])
    node.friends << friend1
    rels = node.friends.rels
    expect(rels.count).to eq(1)
    rel = rels.first
    expect(rel.start_node).to eq(node)
    expect(rel.end_node).to eq(friend1)
  end

  describe 'me.friends << friend_1 << friend' do
    it 'creates several relationships' do
      node.friends << friend1 << friend2
      expect(node.friends.to_a).to match_array([friend1, friend2])
    end
  end

  describe 'me.friends = <array>' do
    it 'creates several relationships' do
      node.friends = [friend1, friend2]
      expect(node.friends.to_a).to match_array([friend1, friend2])
    end

    context 'node with two friends' do
      before(:each) do
        node.friends = [friend1, friend2]
      end

      it 'is not empty' do
        expect(node.friends.any?).to be true
      end

      it 'removes relationships when given a different list' do
        friend3 = Person.create
        node.friends = [friend3]
        expect(node.friends.to_a).to match_array([friend3])
      end

      it 'removes relationships when given a partial list' do
        node.friends = [friend1]
        expect(node.friends.to_a).to match_array([friend1])
      end

      it 'removes all relationships when given an empty list' do
        node.friends = []
        expect(node.friends.to_a).to match_array([])
      end

      it 'occurs within a transaction' do
        friend3 = Person.create(name: 'foo')
        node.friends = [friend1, friend2]
        expect_any_instance_of(Neo4j::ActiveNode::Query::QueryProxy).to receive(:_create_relationship).and_raise('Bar error')
        expect { node.friends = [friend3] }.to raise_error RuntimeError, 'Bar error'
        expect(node.friends.to_a).to include(friend1, friend2)
        expect(node.friends.to_a).not_to include friend3
      end

      it 'can be accessed via [] operator' do
        expect([friend1, friend2]).to include(node.friends[0])
      end

      it 'has a to_s method' do
        expect(node.friends.to_s).to be_a(String)
      end

      it 'has a is_a method' do
        expect(node.friends.is_a?(Neo4j::ActiveNode::HasN::AssociationProxy)).to be true
        expect(node.friends.is_a?(Array)).to be false
        expect(node.friends.is_a?(String)).to be false
      end
    end
  end

  describe 'me.friends#create(other, since: 1994)' do
    describe 'creating relationships to existing nodes' do
      it 'creates a new relationship when given existing nodes and given properties' do
        node.friends.create(friend1, since: 1994)

        r = node.rel(dir: :outgoing, type: 'FRIENDS')

        expect(r[:since]).to eq(1994)
      end

      it 'creates new relationships when given an array of nodes and given properties' do
        node.friends.create([friend1, friend2], since: 1995)

        rs = node.rels(dir: :outgoing, type: 'FRIENDS')

        expect(rs.map(&:end_node)).to match_array([friend1, friend2])
        rs.each do |r|
          expect(r[:since]).to eq(1995)
        end
      end
    end

    describe 'creating relationships and nodes at the same time' do
      let(:node2) { double('unpersisted node', props: {name: 'Brad'}) }

      it 'creates a new relationship when given unpersisted node and given properties' do
        node.friends.create(Person.new(name: 'Brad'), since: 1996)
        # node2.stub(:persisted?).and_return(false)
        # node2.stub(:save).and_return(true)
        # node2.stub(:neo_id).and_return(2)

        # node.friends.create(node2, since: 1996)
        r = node.rel(dir: :outgoing, type: 'FRIENDS')

        expect(r[:since]).to eq(1996)
        expect(r.end_node.name).to eq('Brad')
      end

      it 'creates a new relationship when given an array of unpersisted nodes and given properties' do
        node.friends.create([Person.new(name: 'James'), Person.new(name: 'Cat')], since: 1997)

        rs = node.rels(dir: :outgoing, type: 'FRIENDS')

        expect(rs.map(&:end_node).map(&:name)).to match_array(%w(James Cat))
        rs.each do |r|
          expect(r[:since]).to eq(1997)
        end
      end
    end
  end

  describe 'callbacks' do
    before do
      stub_const('ClazzC', UniqueClass.create do
        include Neo4j::ActiveNode
        property :name

        has_many :out, :knows, type: nil, model_class: self, before: :before_callback
        has_many :in, :knows_me, origin: :knows, model_class: self, after: :after_callback
        has_many :in, :will_fail, origin: :knows, model_class: self, before: :false_callback

        def before_callback(_other)
        end

        def after_callback(_other)
        end

        def false_callback(_other)
          false
        end
      end)
    end

    let(:node) { Person.create }
    let(:friend1) { Person.create }
    let(:friend2) { Person.create }

    let(:callback_friend1) { ClazzC.create }
    let(:callback_friend2) { ClazzC.create }

    it 'calls before_callback when node added to #knows association' do
      expect(callback_friend1).to receive(:before_callback).with(callback_friend2) { expect(callback_friend1.knows.to_a.size).to eq(0) }
      callback_friend1.knows << callback_friend2
    end

    it 'calls after_callback when node added to #knows association' do
      expect(callback_friend1).to receive(:after_callback).with(callback_friend2) { expect(callback_friend2.knows.to_a.size).to eq(1) }
      callback_friend1.knows_me << callback_friend2
    end

    it 'prevents the association from being created if before returns "false" explicitly' do
      callback_friend1.will_fail << callback_friend2
      expect(callback_friend1.knows_me.to_a.size).to eq 0
    end
  end

  describe 'model_class' do
    before(:each) do
      mc = model_class

      stub_active_node_class('Post') do
        has_many :in, :comments, type: :comments_on, model_class: mc
      end

      stub_active_node_class('Comment')

      stub_active_node_class('Person')
    end

    let!(:post) { Post.create }

    let!(:comments) { [Comment.create, Comment.create] }

    let!(:person) { Person.create }

    before(:each) do
      Neo4j::Session.query.match(post: :Post, comment: :Comment).where(comment: {uuid: comments.map(&:uuid)})
        .create('(post)<-[:comments_on]-(comment)').exec

      Neo4j::Session.query.match(post: :Post, person: :Person).where(person: {uuid: person.uuid})
        .create('(post)<-[:comments_on]-(person)').exec
    end

    subject { post.comments.pluck(:uuid).sort }
    context 'model_class: nil' do
      let(:model_class) { nil }
      # Should assume 'Comment' as the model from the association name
      it { is_expected.to eq(comments.map(&:uuid).sort) }
    end

    context "model_class: 'Comment'" do
      let(:model_class) { 'Comment' }
      it { is_expected.to eq(comments.map(&:uuid).sort) }
    end

    context "model_class: 'Person'" do
      let(:model_class) { 'Person' }
      it { is_expected.to eq([person.uuid]) }
    end

    context 'model_class: false' do
      let(:model_class) { false }
      it { is_expected.to eq((comments.map(&:uuid) + [person.uuid]).sort) }
    end

    context "model_class: ['Comment']" do
      let(:model_class) { ['Comment'] }
      it { is_expected.to eq(comments.map(&:uuid).sort) }
    end

    context "model_class: ['Comment', 'Person']" do
      let(:model_class) { %w(Comment Person) }
      it { is_expected.to eq((comments.map(&:uuid) + [person.uuid]).sort) }
    end
  end

  describe 'using mapped_label_name' do
    before do
      stub_const('ClazzC', UniqueClass.create do
        include Neo4j::ActiveNode

        has_many :in, :furrs, type: nil, model_class: 'ClazzD'
      end)

      stub_const('ClazzD', UniqueClass.create do
        include Neo4j::ActiveNode

        self.mapped_label_name = 'Fuur'
      end)
    end

    let(:c1) { ClazzC.create }
    let(:d1) { ClazzD.create }

    it 'should use the mapped_label_name' do
      c1.furrs << d1
      expect(c1.furrs.to_a).to eq([d1])
    end
  end

  describe 'query chaining' do
    before(:each) do
      delete_db
      clear_model_memory_caches

      stub_active_node_class('Dog') do
        property :name

        has_many :out, :toys, type: :has_toy
      end
      stub_active_node_class('Toy') do
        property :name
      end
    end

    context 'one dog, two toys' do
      let!(:sparky) { Dog.create(name: 'Sparky') }
      let!(:spot) { Dog.create(name: 'Spot') }
      let!(:chewmate) { Toy.create(name: 'The Chew Mate') }
      let!(:realcat) { Toy.create(name: 'Real Cat') }

      context 'Sparky has both toys, Spot has just a Real Cat' do
        before(:each) do
          sparky.toys << chewmate
          sparky.toys << realcat

          spot.toys << realcat
        end

        it 'should return all toys for all dogs from Dog.toys' do
          expect(Dog.toys.to_a).to match_array([chewmate, realcat, realcat])
        end

        it 'should return all toys for all dogs specified by where' do
          expect(Dog.where(name: 'Sparky').toys.to_a).to match_array([chewmate, realcat])
          expect(Dog.where(name: 'Spot').toys.to_a).to match_array([realcat])
        end
      end
    end
  end

  describe 'variable-length relationship query' do
    before do
      node.knows << friend1
      friend1.knows << friend2
    end

    context 'as Symbol' do
      context ':any' do
        it 'returns any direct or indirect related node' do
          expect(node.knows(:n, :r, rel_length: :any).to_a).to match_array([friend1, friend2])
        end
      end
    end

    context 'as Fixnum' do
      it 'returns related nodes at exactly `length` hops from start node' do
        expect(node.knows(:n, :r, rel_length: 1).to_a).to match_array([friend1])
        expect(node.knows(:n, :r, rel_length: 2).to_a).to match_array([friend2])
      end
    end

    context 'as Range' do
      it 'returns related nodes within given range of hops from start node' do
        expect(node.knows(nil, nil, rel_length: (0..3)).to_a).to match_array([node, friend1, friend2])
        expect(node.knows(nil, nil, rel_length: (1..2)).to_a).to match_array([friend1, friend2])
        expect(node.knows(nil, nil, rel_length: (2..5)).to_a).to match_array([friend2])
      end
    end

    context 'as Hash' do
      it 'returns related nodes within given range specified by :min/:max options' do
        expect(node.knows(:n, :r, rel_length: {min: 0, max: 3}).to_a).to match_array([node, friend1, friend2])
      end

      it 'accepts missing :min OR :max as denoting open-ended ranges' do
        expect(node.knows(:n, :r, rel_length: {min: 1}).to_a).to match_array([friend1, friend2])
        expect(node.knows(:n, :r, rel_length: {max: 1}).to_a).to match_array([friend1])
      end
    end
  end

  describe 'association "getter" options' do
    before do
      node.knows << friend1
      friend1.knows << friend2
    end

    it 'allows passing only a hash of options when naming node/rel is not needed' do
      expect(node.knows(rel_length: :any).to_a).to match_array([friend1, friend2])
    end
  end

  describe 'transactions' do
    context 'failure' do
      it 'rolls back <<' do
        begin
          tx = Neo4j::Transaction.new
          node.friends << friend1
          tx.failure
        ensure
          tx.close
        end
        expect(node.friends.count).to eq 0
      end

      it 'rolls back =' do
        node.friends = friend1
        begin
          tx = Neo4j::Transaction.new
          node.friends = friend2
          tx.failure
        ensure
          tx.close
        end
        expect(node.friends.first).to eq friend1
      end
    end
  end

  # This block should perhaps be repeated in has_one_spec or extracted into a shared_example
  context 'Empty class' do
    let!(:empty_class) { stub_active_node_class('Foo') }

    describe 'option validation' do
      it 'should require the `:type` key' do
        expect { empty_class.has_many :out, :bars }.to raise_error(ArgumentError, /The 'type' option must be specified/)
        expect { empty_class.has_many :out, :bars, type: :bar }.to_not raise_error
      end

      it 'should not require the `:type` key when `:rel_class` is specified' do
        expect { empty_class.has_many :out, :bars, rel_class: 'ARelClass' }.to_not raise_error
      end

      it 'should not require the `:type` key when `:origin` is specified' do
        expect { empty_class.has_many :out, :bars, origin: :foos }.to_not raise_error
      end

      it 'should only allow one of the the options :type, :origin, or :rel_class' do
        error_regex = /Only one of 'type', 'origin', or 'rel_class' options are allowed/
        expect { empty_class.has_many :out, :bars, type: nil, origin: :foos }.to raise_error(ArgumentError, error_regex)
        expect { empty_class.has_many :out, :bars, type: :bar, origin: :foos }.to raise_error(ArgumentError, error_regex)
        expect { empty_class.has_many :out, :bars, type: :bar, rel_class: 'ARelClass' }.to raise_error(ArgumentError, error_regex)
        expect { empty_class.has_many :out, :bars, origin: :foos, rel_class: 'ARelClass' }.to raise_error(ArgumentError, error_regex)
      end

      it 'should raise an exception if an unknown option is specified' do
        expect do
          empty_class.has_many :out, :bars, type: :bar, unknown_key: true
        end.to raise_error(ArgumentError, /Unknown option\(s\) specified: unknown_key/)
        expect do
          empty_class.has_many :out, :bars, type: :bar, unknown_key: true, unknown_key2: 'test'
        end.to raise_error(ArgumentError, /Unknown option\(s\) specified: unknown_key, unknown_key2/)
      end
    end

    describe 'rel_class magic' do
      it 'should set the association relationship_type when the `type` option is set' do
        expect { empty_class.has_many :out, :bars, type: :bar }.to_not raise_error
        expect(empty_class.associations[:bars].relationship_type).to eq(:bar)
      end

      context 'an ActiveRel class exists' do
        before(:each) do
          stub_active_rel_class('Link') do
            from_class 'Foo'
            to_class 'Bar'
            type 'link'
          end
        end

        it 'should set the association relationship_type when the `rel_class` option is set' do
          expect { empty_class.has_many :out, :bars, rel_class: 'Link' }.to_not raise_error
          expect(empty_class.associations[:bars].relationship_type).to eq(:link)
        end
      end

      context 'another ActiveNode class exists' do
        before(:each) do
          stub_active_node_class('Bar') do
            has_many :in, :foos, type: :barz
          end
        end

        it 'should set the association relationship_type when the `origin` option is set' do
          expect { empty_class.has_many :out, :bars, origin: :foos }.to_not raise_error
          expect(empty_class.associations[:bars].relationship_type).to eq(:barz)
        end
      end
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

    it 'sets IDs for has_many' do
      post = Post.create
      comment = Comment.create

      post.comment_ids = [comment.id]

      post = Post.find(post.id)
      expect(post.comments.to_a).to match_array([comment])
    end

    it 'sets IDs for has_one' do
      post = Post.create
      comment = Comment.create

      comment.post_id = post.id

      comment = Comment.find(comment.id)
      expect(comment.post).to eq(post)
    end

    context 'post is set for comment' do
      before(:each) { comment.post = post }

      it 'returns various IDs for associations' do
        expect(post.comment_ids).to eq([comment.id])
        expect(post.comment_neo_ids).to eq([comment.neo_id])
      end
    end
  end
end
